import torch


def main() -> None:
    print("Hello from cosmos!")
    print("PyTorch version:", torch.__version__)
    print("CUDA available:", torch.cuda.is_available())
    print("CUDA version:", torch.version.cuda)  # type: ignore
    print("cuDNN version:", torch.backends.cudnn.version())
    print("CUDA device count:", torch.cuda.device_count())
    print("CUDA device name:", torch.cuda.get_device_name(0))
    print("CUDA device capability:", torch.cuda.get_device_capability(0))
    print(
        "CUDA device memory:",
        torch.cuda.get_device_properties(0).total_memory / 1024**3,
        "GB",
    )
