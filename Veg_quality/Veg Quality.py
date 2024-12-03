import cv2
import numpy as np
from tensorflow.keras.models import load_model
import matplotlib.pyplot as plt
from tkinter import Tk, Label, Button, filedialog
from PIL import Image, ImageTk

# Load the trained model
model = load_model('my_model.keras')

# List of herb names and their uses
out=['Good',
 'Normal',
 'Bad'
 ]

plant_uses_tamil = ["It is Fresh Brinjal.\nIt's Good for Cook.", 
                    "It is 1 - 3 days Brinjal.\nIt's ok for Cook.",
                    "It is 3 - 7 days Brinjal.\nIt's not ok for Cook."]

class HerbIdentifierApp:
    def __init__(self, master):
        self.master = master
        master.title("Vegetable Quality Checker")

        self.label = Label(master, text="Upload an image of a Veg:")
        self.label.pack()

        self.upload_button = Button(master, text="Upload", command=self.upload_image)
        self.upload_button.pack()

        self.image_label = Label(master)
        self.image_label.pack()

        self.result_label = Label(master, text="", wraplength=400)
        self.result_label.pack()

    def upload_image(self):
        file_path = filedialog.askopenfilename()
        if file_path:
            self.display_image(file_path)
            self.identify_herb(file_path)

    def display_image(self, path):
        img = Image.open(path)
        img = img.resize((224, 224), Image.LANCZOS)  # Use LANCZOS for high-quality downsampling
        img = ImageTk.PhotoImage(img)
        self.image_label.config(image=img)
        self.image_label.image = img

    def identify_herb(self, image_path):
        img = cv2.imread(image_path)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img = cv2.resize(img, (224, 224))
        img = img / 255.0
        img = img.reshape(1, 224, 224, 3)

        res = model.predict(img)
        search_name = out[np.argmax(res)]

        # Find the herb's uses in Tamil
        for i in range(len(out)):
            if out[i] == search_name:
                uses = plant_uses_tamil[i]
                self.result_label.config(text=f"Result: {search_name}\n\n Conditions: \n{uses}")
                break

if __name__ == "__main__":
    root = Tk()
    app = HerbIdentifierApp(root)
    root.mainloop()
