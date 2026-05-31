import os
from flask import Flask, render_template, request, redirect, url_for, flash
from azure.storage.blob import BlobServiceClient, generate_blob_sas, BlobSasPermissions
from datetime import datetime, timedelta, timezone

app = Flask(__name__)
app.secret_key = os.urandom(24)

connection_string = os.environ.get("STORAGE_CONNECTION_STRING")
container_name    = os.environ.get("STORAGE_CONTAINER_NAME", "images")


def get_client():
    return BlobServiceClient.from_connection_string(connection_string)


@app.route("/")
def index():
    client = get_client()
    container = client.get_container_client(container_name)
    blobs = []
    for blob in container.list_blobs():
        account_name = client.account_name
        account_key  = client.credential.account_key
        sas = generate_blob_sas(
            account_name=account_name,
            container_name=container_name,
            blob_name=blob.name,
            account_key=account_key,
            permission=BlobSasPermissions(read=True),
            expiry=datetime.now(timezone.utc) + timedelta(hours=1),
        )
        url = f"https://{account_name}.blob.core.windows.net/{container_name}/{blob.name}?{sas}"
        blobs.append({"name": blob.name, "url": url})
    return render_template("index.html", blobs=blobs)


@app.route("/upload", methods=["GET", "POST"])
def upload():
    if request.method == "POST":
        file = request.files.get("file")
        if not file or file.filename == "":
            flash("No file selected.")
            return redirect(url_for("upload"))
        client = get_client()
        container = client.get_container_client(container_name)
        container.upload_blob(name=file.filename, data=file, overwrite=True)
        flash(f"{file.filename} uploaded successfully.")
        return redirect(url_for("index"))
    return render_template("upload.html")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
