# ---------- Builder: compile dscsm048 on Amazon Linux 2 (dynamic linking) ----------
FROM amazonlinux:2 AS builder
RUN yum -y install gcc gcc-gfortran make git tar gzip which cmake3 file && yum clean all \
 && alternatives --install /usr/bin/cmake cmake /usr/bin/cmake3 1

WORKDIR /build
# Pin to 4.8.5.0 (Dec 2024) for reproducibility
RUN git clone --branch v4.8.5.0 --depth 1 https://github.com/DSSAT/dssat-csm-os.git \
 && sed -i 's/MESSAGE(FATAL_ERROR "No compile flags were found")/message(WARNING "No compile flags were found - proceeding with defaults")/' dssat-csm-os/cmake/Modules/SetCompileFlag.cmake \
 && sed -i 's/SET( *LINKER *.static.*/SET(LINKER "")/I' dssat-csm-os/cmake/Modules/SetFortranFlags.cmake \
 && sed -i 's/-static-libgcc//g; s/-static-libgfortran//g; s/-static-libquadmath//g' dssat-csm-os/cmake/Modules/SetFortranFlags.cmake \
 && sed -i 's/ -libgcc//g' dssat-csm-os/cmake/Modules/SetFortranFlags.cmake
# Data repo provides the canonical structure; we only need OS "Data" here,
# the user supplies Weather/Soil/FileX in their zip. (We still clone for parity.)
RUN git clone --branch v4.8.5.0 --depth 1 https://github.com/DSSAT/dssat-csm-data.git

WORKDIR /build/dssat-csm-os
RUN mkdir -p build && cd build \
 && FC=gfortran cmake -DCMAKE_BUILD_TYPE=Release \
	 -DCMAKE_Fortran_COMPILER=gfortran \
	 -DDYNAMIC_LINK=ON \
	 -DCMAKE_EXE_LINKER_FLAGS="" \
	 -DCMAKE_Fortran_FLAGS="-O2 -fPIC -ffree-line-length-none -std=legacy" .. \
 && cmake --build . -- -j"$(nproc)" \
 && echo 'Built binary info:' && file bin/dscsm048 \
 && echo 'Shared library dependencies:' && ldd bin/dscsm048 \
 && mkdir -p /deps && for f in $(ldd bin/dscsm048 | awk '/\\// {print $3}' | sort -u); do cp -v "$f" /deps/; done

# ---------- Runtime: AWS Lambda Python 3.11 ----------
FROM public.ecr.aws/lambda/python:3.11

# Minimal runtime tree
WORKDIR /var/task
RUN mkdir -p /var/task/bin /var/task/Data /var/task/lib

# Copy model binary and essential Data
COPY --from=builder /build/dssat-csm-os/build/bin/dscsm048 /var/task/bin/dscsm048
COPY --from=builder /deps /var/task/lib
# Explicitly copy critical Fortran runtime libs in case ldd parse missed anything
COPY --from=builder /usr/lib64/libgfortran.so.* /var/task/lib/
COPY --from=builder /usr/lib64/libquadmath.so.* /var/task/lib/
COPY --from=builder /usr/lib64/libgcc_s.so.* /var/task/lib/
# Copy entire Data directory (includes Tools and ancillary directories)
COPY --from=builder /build/dssat-csm-os/Data/ /var/task/Data/
## Supplement with reference data (StandardData, Weather, Soil, Genotype) from data repository
# Copy selected reference folders required for cultivar, soil, weather, and CO2 data
COPY --from=builder /build/dssat-csm-data/Maize/ /var/task/Data/Maize/
COPY --from=builder /build/dssat-csm-data/Soil/ /var/task/Data/Soil/
COPY --from=builder /build/dssat-csm-data/Weather/ /var/task/Data/Weather/
COPY --from=builder /build/dssat-csm-data/Economic/ /var/task/Data/Economic/
COPY --from=builder /build/dssat-csm-data/ClimateChange/ /var/task/Data/ClimateChange/

# App source
COPY src/ /var/task/src/

ENV PATH="/var/task/bin:${PATH}"
ENV LD_LIBRARY_PATH="/var/task/lib:${LD_LIBRARY_PATH}"
# Provide legacy DOS-style root path expected inside DSSATPRO.v48 (\DSSAT48)
# Create a symlink /DSSAT48 -> /tmp/work at runtime via wrapper script.
COPY src/run_dssat_wrapper.sh /var/task/bin/run_dssat_wrapper.sh
RUN chmod +x /var/task/bin/run_dssat_wrapper.sh
# Faster cold start: pre-create work dirs
RUN mkdir -p /tmp/work /tmp/in /tmp/out && chmod +x /var/task/bin/dscsm048 \
 && echo 'Runtime shared libs present:' && ls -1 /var/task/lib || true

# Lambda entrypoint
CMD ["src.handler.lambda_handler"]
