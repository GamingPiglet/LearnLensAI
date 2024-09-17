import flask
import werkzeug
import os

from groq import Groq
from inference_sdk import InferenceHTTPClient
from logging import FileHandler,WARNING

app = flask.Flask(__name__)
app.debug = True
file_handler = FileHandler('errorlog.txt')
file_handler.setLevel(WARNING)
app.config['UPLOAD_FOLDER'] = "./uploads/"

# initialize the client
CLIENT = InferenceHTTPClient(
    api_url="https://detect.roboflow.com",
    api_key="NP3mm8R6qLqwWfBpBhdU"
)

client = Groq(
    api_key="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",
)

@app.route("/")
def home():
    return "Hello World"

@app.route("/infer", methods=["POST"])
def classify():
    imagefile = flask.request.files['image']
    filename = werkzeug.utils.secure_filename(imagefile.filename)
    imagefile.save(os.path.join(app.root_path, app.config["UPLOAD_FOLDER"], filename))
    imagefile.close()
    return CLIENT.infer(os.path.join(app.root_path, app.config["UPLOAD_FOLDER"], filename), model_id="htn-image-detect/4")
    
@app.route("/explain", methods=["POST"])
def ask():
    result = flask.request.json['request']
    print(result)
    prompt = "Explain what a " + result + " is to a 5-year old in 3 paragraphs or less."
    chat_completion = client.chat.completions.create(
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ],
        model="llama3-8b-8192",
    )
    return chat_completion.choices[0].message.content
    
if __name__ == "__main__":
    app.run("0.0.0.0", port="3000")