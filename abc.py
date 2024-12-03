import tkinter as tk
from tkinter import filedialog
from tkinter import Label
from PIL import Image, ImageTk
import numpy as np
import tensorflow as tf

# Load the TFLite model
interpreter = tf.lite.Interpreter(model_path="C:/Users/HP/OneDrive/Desktop/Project/my_model.tflite")
interpreter.allocate_tensors()

# Get input and output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Define the labels
labels = ["Good", "Normal", "Bad"]

# Function to preprocess image
def preprocess_image(image_path):
    img = Image.open(image_path).resize((224, 224))  # Resize to model input size
    img = np.array(img) / 255.0  # Normalize the image
    img = np.expand_dims(img, axis=0).astype(np.float32)  # Expand dimensions for model input
    return img

# Function to classify image
def classify_image():
    file_path = filedialog.askopenfilename()
    if not file_path:
        return

    # Load and preprocess the image
    img = preprocess_image(file_path)

    # Run the TFLite model
    interpreter.set_tensor(input_details[0]['index'], img)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]['index'])
    prediction_index = np.argmax(output_data)
    
    # Map prediction to label
    prediction_label_text = labels[prediction_index]

    # Update GUI with the image and prediction
    img_display = Image.open(file_path).resize((224, 224))
    img_display = ImageTk.PhotoImage(img_display)
    image_label.config(image=img_display)
    image_label.image = img_display
    prediction_label.config(text=f"Prediction: {prediction_label_text}")

# Set up GUI
root = tk.Tk()
root.title("Image Classification")

# Label for displaying the image
image_label = Label(root)
image_label.pack()

# Label for displaying the prediction
prediction_label = Label(root, text="Prediction: ")
prediction_label.pack()

# Button to load and classify an image
button = tk.Button(root, text="Select Image", command=classify_image)
button.pack()

# Run the GUI loop
root.mainloop()
