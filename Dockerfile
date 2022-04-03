ARG UBUNTU_BASE_IMAGE_VERSION=focal-20220316
ARG PYTHON_MAJOR_MINOR_VERSION=3.8
ARG TERRAFORM_VERSION=1.1.7
ARG AZ_CLI_VERSION=2.34.1
ARG SQL_PACKAGE_VERSION=16.0.5400.1
ARG MSSQL_TOOLS_VERSION=17.9.1.1-1

ARG IMAGE_VERSION
ARG IMAGE_CREATION_DATETIME
ARG IMAGE_GIT_SHA1

# Retrieve terraform binary from official terraform docker image
FROM hashicorp/terraform:${TERRAFORM_VERSION} as terraform

# Set up an image with Azure CLI and Python 3
FROM ubuntu:${UBUNTU_BASE_IMAGE_VERSION} as azure-cli
ARG PYTHON_MAJOR_MINOR_VERSION
ARG AZ_CLI_VERSION
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y --no-install-recommends python${PYTHON_MAJOR_MINOR_VERSION}
RUN apt-get install -y --no-install-recommends python3-pip
RUN pip3 install --no-cache-dir setuptools
RUN pip3 install --no-cache-dir azure-cli==${AZ_CLI_VERSION}

# Build release image
FROM ubuntu:${UBUNTU_BASE_IMAGE_VERSION} as release
ARG PYTHON_MAJOR_MINOR_VERSION
ARG SQL_PACKAGE_VERSION
ARG MSSQL_TOOLS_VERSION

ARG IMAGE_VERSION
ARG IMAGE_CREATION_DATETIME
ARG IMAGE_GIT_SHA1

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get install -y --no-install-recommends python${PYTHON_MAJOR_MINOR_VERSION} python3-distutils curl unzip libunwind8 libicu66 jq git gnupg ca-certificates \
  && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && curl -fsSL https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/msprod.list \
  && apt-get update \
  && ACCEPT_EULA=y apt-get -y --no-install-recommends install mssql-tools=${MSSQL_TOOLS_VERSION} unixodbc-dev \
  && rm -rf /var/lib/apt/lists/* \
  && curl -fsSL https://download.microsoft.com/download/b/6/9/b69db004-e5da-46f7-ac3f-e995a27ebbe7/sqlpackage-linux-x64-en-US-${SQL_PACKAGE_VERSION}.zip -o sqlpackage.zip \
  && mkdir /opt/sqlpackage \
  && unzip sqlpackage.zip -d /opt/sqlpackage \
  && echo 'export PATH="$PATH:/opt/sqlpackage:/opt/mssql-tools/bin"' >> /etc/bash.bashrc \
  && chmod a+x /opt/sqlpackage/sqlpackage \
  && rm -rf sqlpackage.zip \
  && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
  && groupadd --gid 1001 nonroot \
  && useradd --uid 1001 --gid 1001 -m nonroot 
COPY --from=terraform /bin/terraform /usr/bin/terraform
COPY --from=azure-cli /usr/local/bin/az* /usr/local/bin/
COPY --from=azure-cli /usr/local/lib/python${PYTHON_MAJOR_MINOR_VERSION}/dist-packages /usr/local/lib/python${PYTHON_MAJOR_MINOR_VERSION}/dist-packages
COPY --from=azure-cli /usr/lib/python3/dist-packages /usr/lib/python3/dist-packages

USER nonroot
ENTRYPOINT [ "/bin/bash" ]

# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.title="terraform-azure"
LABEL org.opencontainers.image.description="Docker image for CI/CD usage, contains Terraform, Azure and SQL Server tools, based on Ubuntu."
LABEL org.opencontainers.image.authors="Michaël Bertoni"
LABEL org.opencontainers.image.url="https://github.com/michaelbertoni/terraform-azure-docker"
LABEL org.opencontainers.image.source="https://github.com/michaelbertoni/terraform-azure-docker"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.created="${IMAGE_CREATION_DATETIME}"
LABEL org.opencontainers.image.revision="${IMAGE_GIT_SHA1}"
LABEL org.opencontainers.image.licenses="MIT"