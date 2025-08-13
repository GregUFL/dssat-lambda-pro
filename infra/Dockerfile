# ---------- Builder: compile dscsm048 on Amazon Linux 2023 ----------
FROM amazonlinux:2023 AS builder
RUN dnf -y install gcc gcc-gfortran cmake make git tar gzip which && dnf clean all

WORKDIR /build
# Pin to 4.8.5.0 (Dec 2024) for reproducibility
RUN git clone --branch v4.8.5.0 --depth 1 https://github.com/DSSAT/dssat-csm-os.git
# Data repo provides the canonical structure; we only need OS "Data" here,
# the user supplies Weather/Soil/FileX in their zip. (We still clone for parity.)
RUN git clone --branch v4.8.5.0 --depth 1 https://github.com/DSSAT/dssat-csm-data.git

WORKDIR /build/dssat-csm-os
RUN mkdir -p build && cd build \
 && FC=gfortran cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_Fortran_COMPILER=gfortran -DCMAKE_Fortran_FLAGS="-O2 -fPIC -ffree-line-length-none -std=legacy" .. \
 && cmake --build . -- -j"$(nproc)"

# ---------- Runtime: AWS Lambda Python 3.11 ----------
FROM public.ecr.aws/lambda/python:3.11

# Minimal runtime tree
WORKDIR /var/task
RUN mkdir -p /var/task/bin /var/task/Data

# Copy model binary and essential Data
COPY --from=builder /build/dssat-csm-os/build/bin/dscsm048 /var/task/bin/dscsm048
COPY --from=builder /build/dssat-csm-os/Data/DSSATPRO.v48 /var/task/Data/DSSATPRO.v48
COPY --from=builder /build/dssat-csm-os/Data/Data.CDE       /var/task/Data/Data.CDE
COPY --from=builder /build/dssat-csm-os/Data/Detail.CDE     /var/task/Data/Detail.CDE
COPY --from=builder /build/dssat-csm-os/Data/StandardData   /var/task/Data/StandardData
COPY --from=builder /build/dssat-csm-os/Data/Genotype       /var/task/Data/Genotype

# App source
COPY src/ /var/task/src/

ENV PATH="/var/task/bin:${PATH}"
# Faster cold start: pre-create work dirs
RUN mkdir -p /tmp/work /tmp/in /tmp/out && chmod +x /var/task/bin/dscsm048

# Lambda entrypoint
CMD ["src.handler.lambda_handler"]
