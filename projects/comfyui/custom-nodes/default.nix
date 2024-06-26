{
  stdenv,
  python3Packages,
  fetchFromGitHub,
  fetchFromHuggingFace,
  fetchzip,
  models,
}: let
  # Patches don't apply to $src, and as with many scripting languages that don't
  # have a build output per se, we just want the script source itself placed
  # into $out.  So just copy everything into $out instead of from $src so we can
  # make sure we get everything in the future, and we use the patched versions.
  install = ''
    shopt -s dotglob
    shopt -s extglob
    cp -r ./!($out|$src) $out/
  '';
  mkComfyUICustomNodes = args:
    stdenv.mkDerivation ({
        installPhase = ''
          runHook preInstall
          mkdir -p $out/
          ${install}
          runHook postInstall
        '';

        passthru.dependencies = {
          pkgs = [];
          models = {};
        };
      }
      // args);
in {
  # https://github.com/Fannovel16/ComfyUI-Frame-Interpolation
  frame-interpolation = mkComfyUICustomNodes {
    pname = "comfyui-frame-interpolation";
    version = "unstable-2024-05-07";
    src = fetchFromGitHub {
      owner = "Fannovel16";
      repo = "ComfyUI-Frame-Interpolation";
      rev = "1c4c4b4f9a99e7e6eb7c5a5f3fdc7c9dfd319357";
      sha256 = "sha256-Qsx2GE7nDf4VDjS9KCzeUmJE5AR9IGm9i2DM5qmXswM=";
    };
    # also need models, e.g. https://github.com/styler00dollar/VSGAN-tensorrt-docker/releases/download/models/rife49.pth
    # see https://github.com/Fannovel16/ComfyUI-Frame-Interpolation/blob/main/vfi_utils.py#L96 for sources
    # and https://github.com/Fannovel16/ComfyUI-Frame-Interpolation/blob/main/vfi_models/rife/__init__.py for required models
    passthru.dependencies.pkgs = with python3Packages; [
      cupy
      einops
      kornia
      numpy
      opencv4
      pillow
      scipy
      torch
      torchvision
      tqdm
    ];
    meta.broken = true;
  };

  # https://github.com/Fannovel16/comfyui_controlnet_aux
  # Nodes for providing ControlNet hint images.
  controlnet-aux = mkComfyUICustomNodes {
    pname = "comfyui-controlnet-aux";
    version = "unstable-2024-06-21";
    pyproject = true;
    passthru.dependencies.pkgs = with python3Packages; [
      addict
      albumentations
      einops
      filelock
      ftfy
      fvcore
      importlib-metadata
      matplotlib
      mediapipe
      numpy
      omegaconf
      onnxruntime
      opencv4
      pillow
      python-dateutil
      pyyaml
      scikit-image
      scikit-learn
      scipy
      svglib
      torchvision
      trimesh
      yacs
      yapf
    ];

    # for some reason, this custom node has its own collection of models, so we
    # just go with it and put them where it expects, not bothering to add them
    # as general model dependencies.
    # TODO: there are probably more models to add
    installPhase = let
      yolox_l = import <nix/fetchurl.nix> {
        name = "yolox_l.onnx";
        url = "https://huggingface.co/yzd-v/DWPose/resolve/main/yolox_l.onnx";
        sha256 = "sha256-eGCued5siaPB63KumidWwMz74Et3kbtYgK+r2XhVpBE=";
      };
      dw-ll_ucoco_384 = import <nix/fetchurl.nix> {
        name = "dw-ll_ucoco_384.onnx";
        url = "https://huggingface.co/yzd-v/DWPose/resolve/main/dw-ll_ucoco_384.onnx";
        sha256 = "sha256-ck9P8kOe1hr7hvuKGVHsOcYiBoKAO0qL1PWYzZE7GEM=";
      };
      # https://huggingface.co/spaces/LiheYoung/Depth-Anything/resolve/main/checkpoints/depth_anything_vitb14.pth
      depth_anything = filename:
        import <nix/fetchurl.nix> {
          name = filename;
          # observed url when it tries to download on its own
          url = "https://huggingface.co/spaces/LiheYoung/Depth-Anything/resolve/main/checkpoints/depth_anything_vitb14.pth";
          sha256 = "sha256-ZK4hSuTidCS2RMSUZMCqJDAW9vdT2VCXyOua0LnLLZs=";
        };
      depth_anything_vitb14 = depth_anything "depth_anything_vitb14.pth";
      depth_anything_vitl14 = depth_anything "depth_anything_vitl14.pth";
      depth_anything_vits14 = depth_anything "depth_anything_vits14.pth";
    in ''
      runHook preInstall
      mkdir -p $out/ckpts/yzd-v/DWPose
      mkdir -p $out/ckpts/LiheYoung/Depth-Anything/checkpoints
      ${install}
      ln -s ${yolox_l} $out/ckpts/yzd-v/DWPose/${yolox_l.name}
      ln -s ${dw-ll_ucoco_384} $out/ckpts/yzd-v/DWPose/${dw-ll_ucoco_384.name}
      ln -s ${depth_anything_vitb14} $out/ckpts/LiheYoung/Depth-Anything/checkpoints/${depth_anything_vitb14.name}
      ln -s ${depth_anything_vitl14} $out/ckpts/LiheYoung/Depth-Anything/checkpoints/${depth_anything_vitl14.name}
      ln -s ${depth_anything_vits14} $out/ckpts/LiheYoung/Depth-Anything/checkpoints/${depth_anything_vits14.name}
      runHook postInstall
    '';

    src = fetchFromGitHub {
      owner = "Fannovel16";
      repo = "comfyui_controlnet_aux";
      rev = "589af18adae7ff50009a0e021781dd1aa39c32e3";
      sha256 = "sha256-J9sJAr+zj2+HNAMQGc9a1i2dcf863y8Hq/ORpLGVWOw=";
      fetchSubmodules = true;
    };
  };

  # https://github.com/Acly/comfyui-inpaint-nodes
  # Provides nodes for doing better inpainting.
  inpaint-nodes = mkComfyUICustomNodes {
    pname = "comfyui-inpaint-nodes";
    version = "unstable-2024-06-02";
    pyproject = true;
    src = fetchFromGitHub {
      owner = "Acly";
      repo = "comfyui-inpaint-nodes";
      rev = "8b800e41bd86ce8f47ec077c839f8b11e52872b2";
      sha256 = "sha256-7WepT234aSMCiaUqiDBH/Xgd8ZvpEc/V5dG3Nld1ysI=";
      fetchSubmodules = true;
    };
  };

  # https://github.com/cubiq/ComfyUI_essentials
  essentials = mkComfyUICustomNodes {
    pname = "comfyui-essentials";
    version = "unstable-2024-06-15";
    src = fetchFromGitHub {
      owner = "cubiq";
      repo = "ComfyUI_essentials";
      rev = "5f1fc52acb03196d683552ea780e5c5325396f18";
      sha256 = "sha256-9Xb9Iqww46qXlEtkA0lbz4zQRPzuN71T1NJjO4B2Rl8=";
    };
    passthru.dependencies = {
      pkgs = with python3Packages; [
        numba
        colour-science
        jsonschema
        pixeloe
        pooch
        pymatting
        rembg
      ];
    };
  };

  # https://github.com/kijai/ComfyUI-IC-Light
  ic-light = mkComfyUICustomNodes {
    pname = "ic-light";
    version = "unstable-2024-06-19";
    src = fetchFromGitHub {
      owner = "kijai";
      repo = "ComfyUI-IC-Light";
      rev = "476303a5a9926e7cf61b2b18567a416d0bdd8d8c";
      sha256 = "sha256-5s2liguOHNwIV9PywFCCbYzROd6KscwYtk+RHEAmPFs=";
    };
    passthru.dependencies = {
      pkgs = with python3Packages; [
        opencv-python
      ];
      models = {
        ic-light_fbc = {
          installPath = "ComfyUI/models/unet/iclight_sd15_fbc.safetensors";
          src = fetchFromHuggingFace {
            owner = "lllyasviel";
            repo = "ic-light";
            resource = "iclight_sd15_fbc.safetensors";
            sha256 = "sha256-u4zO2qSUSxbPqDVq/LwsIXTMTEr1feGRJK4M3dDZaUc=";
          };
        };
        ic-light_fc = {
          installPath = "ComfyUI/models/unet/iclight_sd15_fc.safetensors";
          src = fetchFromHuggingFace {
            owner = "lllyasviel";
            repo = "ic-light";
            resource = "iclight_sd15_fc.safetensors";
            sha256 = "sha256-oDP7qqLz94WfpqRHfuY+u/nBFr81adWBGFbSgH80aM0=";
          };
        };
        ic-light_fcon = {
          installPath = "ComfyUI/models/unet/iclight_sd15_fcon.safetensors";
          src = fetchFromHuggingFace {
            owner = "lllyasviel";
            repo = "ic-light";
            resource = "iclight_sd15_fcon.safetensors";
            sha256 = "sha256-N2Uu8nAoyP25iCgwsWIeTmSNJuGcsgNaavjVLzptjYc=";
          };
        };
      };
    };
  };

  # https://github.com/cubiq/ComfyUI_InstantID
  # only for SD XL
  instantid = mkComfyUICustomNodes {
    pname = "comfyui-instantid";
    version = "unstable-2024-05-08";
    src = fetchFromGitHub {
      owner = "cubiq";
      repo = "ComfyUI_InstantID";
      rev = "d8c70a0cd8ce0d4d62e78653674320c9c3084ec1";
      sha256 = "sha256-zLS2X4bW62Gqo48qB8kONJI1L0+tVKHLZV/fC2B5M9c=";
    };
    passthru.dependencies = {
      pkgs = with python3Packages; [
        insightface
        onnxruntime
      ];
      models = {
        instantid = {
          installPath = "controlnet/diffusion_pytorch_model.safetensors";
          src = fetchFromHuggingFace {
            owner = "InstantX";
            repo = "InstantID";
            resource = "ControlNetModel/diffusion_pytorch_model.safetensors";
            sha256 = "sha256-yBJ76fF0EB69r+6ZZNhWtJtjRDXPbao5bT9ZPPC7uwU=";
          };
        };
        instantid-ipadapter = {
          installPath = "instantid/ip-adapter.bin";
          src = fetchFromHuggingFace {
            owner = "InstantX";
            repo = "InstantID";
            resource = "ip-adapter.bin";
            sha256 = "sha256-ArNhjjbYA3hBZmYFIAmAiagTiOYak++AAqp5pbHFRuE=";
          };
        };
        antelopev2 = {
          installPath = "insightface/models/antelopev2";
          src = fetchzip {
            url = "https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip";
            sha256 = "sha256-pUEM9LcVmTUemvglPZxiIvJd18QSDjxTEwAjfIWZ93g=";
          };
        };
      };
    };
  };

  # https://github.com/cubiq/ComfyUI_IPAdapter_plus
  # This allows use of IP-Adapter models (IP meaning Image Prompt in this
  # context).  IP-Adapter models can out-perform fine tuned models
  # (checkpoints?).
  ipadapter-plus = mkComfyUICustomNodes {
    pname = "comfyui-ipadapter-plus";
    version = "unstable-2024-06-9";
    pyproject = true;
    src = fetchFromGitHub {
      owner = "cubiq";
      repo = "ComfyUI_IPAdapter_plus";
      rev = "7d8adaec730bff243cc3026eed5111695cc5ed4e";
      sha256 = "sha256-F0mmJ2X+eEijsV24s9I+zP90wpNC9pu8IwdEzq0xj8M=";
      fetchSubmodules = true;
    };

    passthru.dependencies = {
      pkgs = with python3Packages; [
        insightface
        onnxruntime
      ];
      models = {
        inherit (models) inswapper_128;
        buffalo_l = {
          installPath = "insightface/models/buffalo_l";
          src = fetchzip {
            url = "https://github.com/deepinsight/insightface/releases/download/v0.7/buffalo_l.zip";
            sha256 = "sha256-ayiIkXXgg83aPhAFs2WXvDxHqKizpVuAKF2AjZyjct4=";
            stripRoot = false;
          };
        };
      };
    };
  };

  # https://github.com/Acly/comfyui-tooling-nodes
  # Make ComfyUI more friendly towards API usage.
  tooling-nodes = mkComfyUICustomNodes {
    pname = "comfyui-tooling-nodes";
    version = "unstable-2024-06-20";
    pyproject = true;
    src = fetchFromGitHub {
      owner = "Acly";
      repo = "comfyui-tooling-nodes";
      rev = "aff32e8da6db5db73bc6f84b30c87862e211544c";
      sha256 = "sha256-6i1PGog8ZNBwO9FDFjneWRCx8Cn6N1N1hZhzI64GLNk=";
      fetchSubmodules = true;
    };
  };

  # Handle upscaling of smaller images into larger ones.  This is helpful to go
  # from a prototyped image to a highly detailed, high resolution version.
  ultimate-sd-upscale = mkComfyUICustomNodes {
    pname = "ultimate-sd-upscale";
    version = "unstable-2024-03-30";
    src = fetchFromGitHub {
      owner = "ssitu";
      repo = "ComfyUI_UltimateSDUpscale";
      rev = "b303386bd363df16ad6706a13b3b47a1c2a1ea49";
      sha256 = "sha256-kcvhafXzwZ817y+8LKzOkGR3Y3QBB7Nupefya6s/HF4=";
      fetchSubmodules = true;
    };
  };

  ## Broken due to runtime mischief
  # https://github.com/Gourieff/comfyui-reactor-node
  # Fast and simple face swap node(s).
  reactor-node = mkComfyUICustomNodes {
    pname = "comfyui-reactor-node";
    version = "unstable-2024-04-07";
    pyproject = true;
    passthru.dependencies = {
      pkgs = with python3Packages; [
        insightface
        onnxruntime
      ];
      models = {
        # expects these directories to exist:
        #   models/reactor/faces
        #   models/facerestore_models
        #   models/ultralytics/bbox
        #   models/ultralytics/segm
        #   models/sams
        # but it also seems to want arbitrary write-access to the models dir......

        inherit
          (models)
          inswapper_128
          "GFPGANv1.3"
          "GFPGANv1.4"
          "codeformer-v0.1.0"
          GPEN-BFR-512
          ;
      };
    };

    src = fetchFromGitHub {
      owner = "Gourieff";
      repo = "comfyui-reactor-node";
      rev = "05bf228e623c8d7aa5a33d3a6f3103a990cfe09d";
      sha256 = "sha256-2IrpOp7N2GR1zA4jgMewAp3PwTLLZa1r8D+/uxI8yzw=";
      fetchSubmodules = true;
    };

    meta.broken = true;
  };
}
