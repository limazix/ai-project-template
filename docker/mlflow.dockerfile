FROM docker.io/continuumio/miniconda3:latest

RUN pip install mlflow boto3 pymysql