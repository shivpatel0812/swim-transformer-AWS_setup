import numpy as np
import matplotlib.pyplot as plt

# 1. Load the .npy file
def load_npy_file(file_path):
    """
    Load and inspect the .npy file.

    Args:
        file_path (str): Path to the .npy file.

    Returns:
        np.ndarray: Loaded segmentation data.
    """
    try:
        data = np.load(file_path)
        print(f"Successfully loaded .npy file: {file_path}")
        print(f"Data Shape: {data.shape}")
        print(f"Data Type: {data.dtype}")
        return data
    except Exception as e:
        print(f"Error loading .npy file: {e}")
        return None

# 2. Visualize the segmentation masks
def visualize_segmentation(data):
    """
    Visualize segmentation masks from the .npy file.

    Args:
        data (np.ndarray): Segmentation masks stored in a NumPy array.

    Returns:
        None
    """
    if data is None:
        print("No data to visualize.")
        return

    # Check if data is 3D
    if len(data.shape) != 3:
        print("Data is not a 3D array. Cannot visualize segmentation masks.")
        return

    # Visualize each segmentation mask
    for i in range(data.shape[0]):
        plt.imshow(data[i], cmap='gray')
        plt.title(f"Segmentation Mask {i + 1}")
        plt.colorbar()
        plt.show()

# Main function to load and visualize
def main():
    # Path to the .npy file
    file_path = 'result_dir_prefix/predictions/YC8_03.16.18-Slice2-P12/Stack_11_to_21.npy'  # Replace with your actual file path

    # Load the .npy file
    segmentation_data = load_npy_file(file_path)

    # Visualize the segmentation masks
    visualize_segmentation(segmentation_data)

# Run the script
if __name__ == "__main__":
    main()
