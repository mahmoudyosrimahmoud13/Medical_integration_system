# Small image: DrugBank lookup only.   docker build -t healthhub-ai .
# With the model (adds PyTorch, CPU):   docker build --build-arg WITH_MODEL=1 -t healthhub-ai .
FROM python:3.12-slim
ARG WITH_MODEL=0
WORKDIR /app
COPY requirements.txt requirements-model.txt ./
RUN pip install --no-cache-dir -r requirements.txt && \
    if [ "$WITH_MODEL" = "1" ]; then \
      pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu && \
      pip install --no-cache-dir -r requirements-model.txt ; fi
COPY ddi_service ddi_service
COPY tools tools
COPY weights weights
RUN python tools/fetch_data.py /app/data
ENV USE_MODEL=${WITH_MODEL}
# USE_MODEL accepts 0/1 as false/true
EXPOSE 8001
CMD ["uvicorn", "ddi_service.main:app", "--host", "0.0.0.0", "--port", "8001"]
