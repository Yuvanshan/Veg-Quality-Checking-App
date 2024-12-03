from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
import os
import tensorflow as tf
import numpy as np
from PIL import Image
import io


from flask_cors import CORS  # Import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes


# Define the allowed file extensions
ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png'}

out = ['Good', 'Normal', 'Bad']
Veg_res = [
    "It is Fresh Brinjal.\nIt's Good for Cook.",
    "It is 1 - 3 days Brinjal.\nIt's ok for Cook.",
    "It is 3 - 7 days Brinjal.\nIt's not good for Cook."
]

# Set the path for uploaded files
UPLOAD_FOLDER = 'uploads'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Load your model
model = tf.lite.Interpreter(model_path="C:/Users/HP/OneDrive/Desktop/Project/my_model.tflite")
model.allocate_tensors()

# Function to check if the file has an allowed extension
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Function to process image for model prediction
def preprocess_image(image_path):
    # Open image
    img = Image.open(image_path)
    # Resize image to the expected input shape of the model
    img = img.resize((224, 224))  # Change to model's input size (e.g., 224x224)
    img = np.array(img).astype(np.float32)
    # Normalize the image
    img = img / 255.0
    # Expand dimensions to match model input (batch_size, height, width, channels)
    img = np.expand_dims(img, axis=0)
    return img

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'image' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    
    file = request.files['image']
    
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    if file and allowed_file(file.filename):
        # Save the file securely
        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)

        # Preprocess the image for model input
        image_data = preprocess_image(filepath)

        # Get model input and output tensors
        input_details = model.get_input_details()
        output_details = model.get_output_details()

        # Set the tensor with the preprocessed image
        model.set_tensor(input_details[0]['index'], image_data)

        # Run inference
        model.invoke()

        # Get the output and process prediction
        output_data = model.get_tensor(output_details[0]['index'])
        predicted_class = np.argmax(output_data)

        # Create response based on the prediction
        result = {
            'prediction': out[predicted_class],
            'benefits': Veg_res[predicted_class]
        }

        return jsonify(result)

    return jsonify({'error': 'Invalid file type. Only jpg, jpeg, png are allowed.'}), 400

if __name__ == '__main__':
    app.run(debug=True)
