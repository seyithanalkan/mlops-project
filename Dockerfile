FROM python:3.10-slim AS base

# install venv & curl
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y python3-venv curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# create & activate venv
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Upgrade pip & wheel first
RUN pip install --no-cache-dir --upgrade pip wheel

# ---- New steps to utterly cleanse setuptools ----
RUN pip uninstall -y setuptools || true
RUN find "$VIRTUAL_ENV"/lib/python*/site-packages/ \
     -maxdepth 1 -type d -name "setuptools-*.dist-info" \
     -exec rm -rf {} +
RUN pip install --no-cache-dir --force-reinstall setuptools>=78.1.1
# ---------------------------------------------------

COPY . /app

# Install your requirements
RUN pip install --no-cache-dir -r requirements.txt

# In case a dep downgrades setuptools, force it *again*
RUN pip install --no-cache-dir --force-reinstall setuptools>=78.1.1

# ── Training stage ──
FROM base AS train
RUN chmod +x run_pipeline.sh
ENTRYPOINT ["bash", "run_pipeline.sh"]

# ── Serving stage ──
FROM base AS serve
EXPOSE 8000
ENV PYTHONPATH=/app
CMD ["uvicorn", "src.serve.app:app", "--host", "0.0.0.0", "--port", "8000"]
