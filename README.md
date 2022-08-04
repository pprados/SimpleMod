# SimpleMod

## Motivation

This is a implementation of a very simple "model" to test the architecture
and framworks, and extract some pattern to the real implementations.

## Synopsis

With this project, we will check differents approchs to implement a kind-of model.

## The latest version

```shell
git clone --recurse-submodules https://github.com/pprados/simplemod.git
```

## Installation

Go inside the directory and
```bash
$ make configure
$ conda activate simplemod
$ make docs
```

## Tests

To test the project
```bash
$ make test
```

To validate the typing
```bash
$ make typing
```
or to add type in code
```bash
$ make add-typing
```

To validate all the project
```bash
$ make validate
```

## Project Organization

    ├── Makefile              <- Makefile with commands like `make data` or `make train`
    ├── README.md             <- The top-level README for developers using this project.
    ├── data
    │
    ├── docs                  <- A default Sphinx project; see sphinx-doc.org for details
    │
    ├── notebooks             <- Jupyter notebooks. Naming convention is a number (for ordering),
    │                            the creator's initials, and a short `-` delimited description, e.g.
    │                            `1.0-jqp-initial-data-exploration`.
    │
    ├── setup.py              <- makes project pip installable (pip install -e .[tests])
    │                            so sources can be imported and dependencies installed
    ├── simplemod                <- Source code for use in this project
    │   ├── __init__.py       <- Makes src a Python module
    │   └── *.py              <- Codes
    │
    └── tests                 <- Unit and integrations tests ((Mark directory as a sources root).


