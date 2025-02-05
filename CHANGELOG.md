# ChangeLog

## 0.6.0

- Python 3.12
- `cdktf-provider-sync` downloads the Terraform providers based on the Python CDKTF packages in your `pyproject.toml`

## 0.5.0

- hook scripts support

## 0.4.0

- CDKTF 0.20.11

## 0.3.0

- CDKTF 0.20.9
- Don't include `uv` and a `.venv` in the image. Must be done in the ERv2 module
- Add `entrypoint.sh`
- Docker image tags based on CDKTF, Terraform, and Python versions
- `cdktf-provider-sync` command to pre-download Terraform providers in a sub-image

## 0.2.0

- Use Konflux to build the image
- Use [uv](https://docs.astral.sh/uv/) for Python dependency management
- Run container as non-root user
- Provide a standard `.venv`
- Basic image tests
- Add a LICENSE file

## 0.1.0

Switched to ubi-minimal to reduce the overall image size.

- Base: ubi9/ubi-minimal:9.4
- NodeJS 20
- CDKTF 0.20.8
- Terraform 1.6.6

## 0.0.1

- Base: ubi8/NodeJS-18:1-81
- CDKTF 0.20.8
- Terraform 1.6.6
