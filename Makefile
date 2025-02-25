#!/usr/bin/env make

# SNIPPET Le shebang précédant permet de creer des alias des cibles du Makefile.
# Il faut que le Makefile soit executable
# 	chmod u+x Makefile
# 	git update-index --chmod=+x Makefile
# Puis, par exemple
# 	ln -s Makefile configure
# 	ln -s Makefile test
# 	ln -s Makefile train
# 	./configure		# Execute make configure
# 	./test 			# Execute make test
#   ./train 		# Train the model
# Attention, il n'est pas possible de passer les paramètres aux scripts

# ---------------------------------------------------------------------------------------
# SNIPPET pour vérifier la version du programme `make`.
# WARNING: Use make >4.0
ifeq ($(shell echo "$(shell echo $(MAKE_VERSION) | sed 's@^[^0-9]*\([0-9]\+\).*@\1@' ) >= 4" | bc -l),0)
$(error Bad make version, please install make >= 4)
endif
# ---------------------------------------------------------------------------------------
# SNIPPET pour changer le mode de gestion du Makefile.
# Avec ces trois paramètres, toutes les lignes d'une recette sont invoquées dans le même shell.
# Ainsi, il n'est pas nécessaire d'ajouter des '&&' ou des '\' pour regrouper les lignes.
# Comme Make affiche l'intégralité du block de la recette avant de l'exécuter, il n'est
# pas toujours facile de savoir quel est la ligne en échec.
# Je vous conseille dans ce cas d'ajouter au début de la recette 'set -x'
# Attention : il faut une version > 4 de  `make` (`make -v`).
# Les versions CentOS d'Amazone ont une version 3.82.
# Utilisez `conda install -n $(VENV_AWS) make>=4 -y`
# WARNING: Use make >4.0
SHELL=/bin/bash
.SHELLFLAGS = -e -c
.ONESHELL:


# ---------------------------------------------------------------------------------------
# SNIPPET pour injecter les variables de .env.
ifneq (,$(wildcard .env))
include .env
endif


# ---------------------------------------------------------------------------------------
# SNIPPET pour détecter l'OS d'exécution.
ifeq ($(OS),Windows_NT)
    OS := Windows
    EXE:=.exe
    SUDO?=
else
    OS := $(shell sh -c 'uname 2>/dev/null || echo Unknown')
    EXE:=
    SUDO?=
endif


# ---------------------------------------------------------------------------------------
# SNIPPET pour détecter la présence d'un GPU afin de modifier le nom du projet
# et ses dépendances si nécessaire.
ifndef USE_GPU
ifneq ("$(wildcard /proc/driver/nvidia)","")
USE_GPU:=-gpu
else ifdef CUDA_HOME
USE_GPU:=-gpu
endif
endif

ifdef USE_GPU
CUDA_VER=$(shell nvidia-smi | awk -F"CUDA Version:" 'NR==3{split($$2,a," ");print a[1]}')
endif

# ---------------------------------------------------------------------------------------
# SNIPPET pour identifier le nombre de processeur
NPROC?=$(shell nproc)

# ---------------------------------------------------------------------------------------
# SNIPPET pour pouvoir lancer un browser avec un fichier local
define BROWSER
	python -c '
	import os, sys, webbrowser
	from urllib.request import pathname2url

	webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])), autoraise=True)
	sys.exit(0)
	'
endef

# ---------------------------------------------------------------------------------------
# SNIPPET pour supprimer le parallelisme pour certaines cibles
# par exemple pour release
ifneq ($(filter configure release clean functional-test% upgrade-%,$(MAKECMDGOALS)),)
.NOTPARALLEL:
endif
#

# ---------------------------------------------------------------------------------------
# SNIPPET pour récupérer les séquences de caractères pour les couleurs
# A utiliser avec un
# echo -e "Use '$(cyan)make$(normal)' ..."
# Si vous n'utilisez pas ce snippet, les variables de couleurs non initialisés
# sont simplement ignorées.
ifneq ($(TERM),)
normal:=$(shell tput sgr0)
bold:=$(shell tput bold)
red:=$(shell tput setaf 1)
green:=$(shell tput setaf 2)
yellow:=$(shell tput setaf 3)
blue:=$(shell tput setaf 4)
purple:=$(shell tput setaf 5)
cyan:=$(shell tput setaf 6)
white:=$(shell tput setaf 7)
gray:=$(shell tput setaf 8)
endif

# ---------------------------------------------------------------------------------------
# SNIPPET pour gérer le projet, le virtualenv conda et le kernel.
# Par convention, les noms du projet, de l'environnement Conda ou le Kernel Jupyter
# correspondent au nom du répertoire du projet.
# Il est possible de modifier cela en valorisant les variables VENV, KERNEL, et/ou PRJ.
# avant le lancement du Makefile (`VENV=cntk_p36 make`)
PRJ:=$(shell basename $(shell pwd))
VENV ?= $(PRJ)
KERNEL ?=$(VENV)
PRJ_PACKAGE:=$(PRJ)
PYTHON_VERSION:=3.9
PYTHONPATH=pandera:virtual_dataframe
CUDF_VER?=22.06
PYTHON_SRC=$(shell find -L "$(PRJ)" -type f -iname '*.py' | grep -v __pycache__)
PYTHON_TST=$(shell find -L tests -type f -iname '*.py' | grep -v __pycache__)
VDF_MODES=pandas cudf dask dask_cudf

DOCKER_REPOSITORY = $(USER)
# Data directory (can be in other place, in VM or Docker for example)
export DATA?=data

# Conda environment
CONDA_BASE:=$(shell AWS_DEFAULT_PROFILE=default conda info --base)
CONDA_PACKAGE:=$(CONDA_PREFIX)/lib/python$(PYTHON_VERSION)/site-packages
CONDA_PYTHON:=$(CONDA_PREFIX)/bin/python
CONDA_ARGS?=-c rapidsai -c nvidia -c conda-forge
export VIRTUAL_ENV=$(CONDA_PREFIX)

PIP_PACKAGE:=$(CONDA_PACKAGE)/$(PRJ_PACKAGE).egg-link
PIP_ARGS?=
JUPYTER_LABEXTENSIONS?=dask-labextension
JUPYTER_DATA_DIR:=$(shell jupyter --data-dir 2>/dev/null || echo "~/.local/share/jupyter")
JUPYTER_LABEXTENSIONS_DIR:=$(CONDA_PREFIX)/share/jupyter/labextensions
_JUPYTER_LABEXTENSIONS:=$(foreach ext,$(JUPYTER_LABEXTENSIONS),$(JUPYTER_LABEXTENSIONS_DIR)/$(ext))


# ---------------------------------------------------------------------------------------
# SNIPPET pour ajouter des repositories complémentaires à PIP.
# A utiliser avec par exemple
# pip $(EXTRA_INDEX) install ...
EXTRA_INDEX:=--extra-index-url=https://pypi.anaconda.org/octo

# ---------------------------------------------------------------------------------------
# SNIPPET pour gérer permettre d'invoquer une cible make avec des paramètres.
# Pour cela, toutes les cibles inconnues, sont considérées comme des paramètres
# et se retrouvent dans la variables ARGS. Pour que ces cibles ne génères pas d'erreurs
# on ajoute une règle pour ignorer toutes les cibles inconnes.
# Cela est en commentaire et doit être activé spécifiquement.
# Calculate the make extended parameter
# Keep only the unknown target
#ARGS = `ARGS="$(filter-out $@,$(MAKECMDGOALS))" && echo $${ARGS:-${1}}`
# Hack to ignore unknown target. May be used to calculate parameters
#%:
#	@:

# ---------------------------------------------------------------------------------------
# SNIPPET pour gérer automatiquement l'aide du Makefile.
# Il faut utiliser des commentaires commençant par '##' précédant la ligne des recettes,
# pour une production automatique de l'aide.
.PHONY: help
.DEFAULT: help

## Print all majors target
help:
	@echo "$(bold)Available rules:$(normal)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=20 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')

	echo -e "Use '$(cyan)make -jn ...$(normal)' for Parallel run"
	echo -e "Use '$(cyan)make -B ...$(normal)' to force the target"
	echo -e "Use '$(cyan)make -n ...$(normal)' to simulate the build"

# ---------------------------------------------------------------------------------------
# SNIPPET pour affichier la valeur d'une variable d'environnement
# tel quelle est vue par le Makefile. Par exemple `make dump-CONDA_PACKAGE`
.PHONY: dump-*
dump-%:
	@if [ "${${*}}" = "" ]; then
		echo "Environment variable $* is not set";
		exit 1;
	else
		echo "$*=${${*}}";
	fi

# ---------------------------------------------------------------------------------------
# SNIPPET pour invoker un shell dans le context du Makefile
.PHONY: shell
## Run shell in Makefile context
shell:
	$(SHELL)


# ---------------------------------------------------------------------------------------
# SNIPPET pour gérer les Notebooks avec GIT.
# Les recettes suivantes s'assure que git est bien initialisé
# et ajoute des recettes pour les fichiers *.ipynb
# et eventuellement pour les fichiers *.csv.
#
# Pour cela, un fichier .gitattribute est maintenu à jour.
# Les recettes pour les notebooks se chargent de les nettoyer avant de les commiter.
# Pour cela, elles appliquent `jupyter nb-convert` à la volée. Ainsi, les comparaisons
# de version ne sont plus parasités par les data.
#
# Les scripts pour les CSV utilisent le composant `daff` (pip install daff)
# pour comparer plus efficacement les évolutions des fichiers csv.
# Un `git diff toto.csv` est plus clair.

# S'assure de la présence de git (util en cas de synchronisation sur le cloud par exemple,
# après avoir exclus le répertoire .git (cf. ssh-ec2)
.git:
	@if [[ ! -d .git ]]; then
		@git init -q
		git commit --allow-empty -m "Create project $(PRJ)"
	fi

# Règle technique importante, invoquées lors du `git commit` d'un fichier *.ipynb via
# le paramètrage de `.gitattributes`.
.PHONY: pipe_clear_jupyter_output
pipe_clear_jupyter_output:
	jupyter nb-convert --to notebook --ClearOutputPreprocessor.enabled=True <(cat <&0) --stdout 2>/dev/null

# Règle qit install git lfs si nécessaire
.git/hooks/post-checkout:
ifeq ($(shell which git-lfs >/dev/null ; echo "$$?"),0)
	# Add git lfs if possible
	@git lfs install >/dev/null
	# Add some extensions in lfs
	@git lfs track "*.pkl" --lockable  >/dev/null
	@git lfs track "*.bin" --lockable  >/dev/null
	@git lfs track "*.jpg" --lockable  >/dev/null
	@git lfs track "*.jpeg" --lockable >/dev/null
	@git lfs track "*.gif" --lockable  >/dev/null
	@git lfs track "*.png" --lockable  >/dev/null
endif

# Règle qui ajoute la validation du project avant un push sur la branche master.
# Elle ajoute un hook git pour invoquer `make validate` avant de pusher. En cas
# d'erreur, le push n'est pas possible.
# Pour forcer le push, malgres des erreurs lors de l'exécution de 'make validate'
# utilisez 'FORCE=y git push'.
# Pour supprimer ce comportement, il faut modifier le fichier .git/hooks/pre-push
# et supprimer la règle du Makefile, ou bien,
# utiliser un fichier vide 'echo ''> .git/hooks/pre-push'
.git/hooks/pre-push:.git/hooks/post-checkout | .git
	@# Add a hook to validate the project before a git push
	cat >>.git/hooks/pre-push <<PRE-PUSH
	#!/usr/bin/env sh
	# Validate the project before a push
	if test -t 1; then
		ncolors=$$(tput colors)
		if test -n "\$$ncolors" && test \$$ncolors -ge 8; then
			normal="\$$(tput sgr0)"
			red="\$$(tput setaf 1)"
	        green="\$$(tput setaf 2)"
			yellow="\$$(tput setaf 3)"
		fi
	fi
	branch="\$$(git branch | grep \* | cut -d ' ' -f2)"
	if [ "\$${branch}" = "master" ] && [ "\$${FORCE}" != y ] ; then
		printf "\$${green}Validate the project before push the commit... (\$${yellow}make validate\$${green})\$${normal}\n"
		make validate
		ERR=\$$?
		if [ \$${ERR} -ne 0 ] ; then
			printf "\$${red}'\$${yellow}make validate\$${red}' failed before git push.\$${normal}\n"
			printf "Use \$${yellow}FORCE=y git push\$${normal} to force.\n"
			exit \$${ERR}
		fi
	fi
	PRE-PUSH
	chmod +x .git/hooks/pre-push

# Init git configuration
.gitattribute: | .git .git/hooks/pre-push  # Configure git
	@git config --local core.autocrlf input
	# Set tabulation to 4 when use 'git diff'
	@git config --local core.page 'less -x4'

ifeq ($(shell which jupyter >/dev/null ; echo "$$?"),0)
	# Add rules to manage the output data of notebooks
	@git config --local filter.dropoutput_jupyter.clean "make --silent pipe_clear_jupyter_output"
	@git config --local filter.dropoutput_jupyter.smudge cat
	@[ -e .gitattributes ] && grep -v dropoutput_jupyter .gitattributes >.gitattributes.new 2>/dev/null || true
	@[ -e .gitattributes.new ] && mv .gitattributes.new .gitattributes || true
	@echo "*.ipynb filter=dropoutput_jupyter diff=dropoutput_jupyter -text" >>.gitattributes
endif

ifeq ($(shell which daff >/dev/null ; echo "$$?"),0)
	# Add rules to manage diff with daff for CSV file
	@git config --local diff.daff-csv.command "daff.py diff --git"
	@git config --local merge.daff-csv.name "daff.py tabular merge"
	@git config --local merge.daff-csv.driver "daff.py merge --output %A %O %A %B"
	@[ -e .gitattributes ] && grep -v daff-csv .gitattributes >.gitattributes.new 2>/dev/null
	@[ -e .gitattributes.new ] && mv .gitattributes.new .gitattributes
	@echo "*.[tc]sv diff=daff-csv merge=daff-csv -text" >>.gitattributes
endif


# ---------------------------------------------------------------------------------------
# SNIPPET pour vérifier la présence d'un environnement Conda conforme
# avant le lancement d'un traitement.
# Il faut ajouter $(VALIDATE_VENV) dans les recettes
# et choisir la version à appliquer.
# Soit :
# - CHECK_VENV pour vérifier l'activation d'un VENV avant de commencer
# - ACTIVATE_VENV pour activer le VENV avant le traitement
# Pour cela, sélectionnez la version de VALIDATE_VENV qui vous convient.
# Attention, toute les règles proposées ne sont pas compatible avec le mode ACTIVATE_VENV
CHECK_VENV=@if [[ "$(VENV)" != "$(CONDA_DEFAULT_ENV)" ]] ; \
  then echo -e "$(green)Use: $(cyan)conda activate $(VENV)$(green) before using 'make'$(normal)"; exit 1 ; fi

ACTIVATE_VENV=source $(CONDA_BASE)/etc/profile.d/conda.sh && conda activate $(VENV) $(CONDA_ARGS)
DEACTIVATE_VENV=source $(CONDA_BASE)/etc/profile.d/conda.sh && conda deactivate

VALIDATE_VENV=$(CHECK_VENV)
#VALIDATE_VENV=$(ACTIVATE_VENV)

# ---------------------------------------------------------------------------------------
# SNIPPET pour gérer correctement toute les dépendences python du projet.
# La cible `requirements` se charge de gérer toutes les dépendences
# d'un projet Python. Dans le SNIPPET présenté, il y a de quoi gérer :
# - les dépendances PIP
# - la gestion d'un kernel pour Jupyter
#
# Il suffit, dans les autres de règles, d'ajouter la dépendances sur `$(REQUIREMENTS)`
# pour qu'un simple `make test` garantie la mise à jour de l'environnement avant
# le lancement des tests par exemple.
#
# Pour cela, il faut indiquer dans le fichier 'setup.py', toutes les dépendances
# de run et de test (voir le modèle de `setup.py` proposé)

# All dependencies of the project must be here
RAPIDS=$(CONDA_PACKAGE)/cuda
.PHONY: install-rapids
## Install NVidia rapids framework
install-rapids: $(RAPIDS)
$(RAPIDS):
ifeq ($(USE_GPU),-gpu)
	@echo "$(green)  Install NVidia Rapids...$(normal)"
	conda install -q -y $(CONDA_ARGS) \
		cudf==$(CUDF_VER) \
		cudatoolkit==$(CUDA_VER) \
		dask-cuda \
		dask-cudf \
		dask-labextension
else
	conda install -q -y $(CONDA_ARGS) \
		dask-labextension
endif
	touch $(RAPIDS)

.PHONY: requirements dependencies
REQUIREMENTS=$(RAPIDS) $(PIP_PACKAGE) \
	.gitattributes
requirements: $(REQUIREMENTS)
dependencies: requirements


# ---------------------------------------------------------------------------------------
# SNIPPET pour gérer le mode offline.
# La cible `offline` permet de télécharger toutes les dépendences, pour pouvoir les utiliser
# ensuite sans connexion. Ensuite, il faut valoriser la variable d'environnement OFFLINE
# à True avant le lancement du make pour une utilisation sans réseau.
# `export OFFLINE=True
# make ...
# unset OFFLINE`

# TODO: faire une regle ~/.offline et un variable qui s'ajuste pour tirer la dépendances ?
# ou bien le faire à la main ?
# Download dependencies for offline usage
~/.mypypi: setup.py
	pip download '.[dev,test]' --dest ~/.mypypi
# Download modules and packages before going offline
offline: ~/.mypypi
ifeq ($(OFFLINE),True)
CONDA_ARGS+=--use-index-cache --use-local --offline
PIP_ARGS+=--no-index --find-links ~/.mypypi
endif

$(CONDA_PYTHON):
	@$(VALIDATE_VENV)
	conda install -q "python=$(PYTHON_VERSION).*" -y $(CONDA_ARGS)

# Rule to update the current venv, with the dependencies describe in `setup.py`
$(PIP_PACKAGE): $(CONDA_PYTHON) $(RAPIDS) setup.py | .git # Install pip dependencies
	$(VALIDATE_VENV)
	echo -e "$(cyan)Install setup.py dependencies ... (may take minutes)$(normal)"
	pip install $(PIP_ARGS) $(EXTRA_INDEX) -e '.[dev,test]' | grep -v 'already satisfied' || true
	pip install -e 'virtual-dataframe/[all]'
	pip install -e pandera/
	echo -e "$(cyan)setup.py dependencies updated$(normal)"
	touch $(PIP_PACKAGE)

# ---------------------------------------------------------------------------------------
# SNIPPET pour gérer les kernels Jupyter
# Intall a Jupyter kernel
$(JUPYTER_DATA_DIR)/kernels/$(KERNEL): $(REQUIREMENTS)
	@$(VALIDATE_VENV)
	python -O -m ipykernel install --user --name $(KERNEL)
	echo -e "$(cyan)Kernel $(KERNEL) installed$(normal)"

# Remove the Jupyter kernel
.PHONY: remove-kernel
remove-kernel: $(REQUIREMENTS)
	@echo y | jupyter kernelspec uninstall $(KERNEL) 2>/dev/null || true
	echo -e "$(yellow)Warning: Kernel $(KERNEL) uninstalled$(normal)"

# ---------------------------------------------------------------------------------------
# SNIPPET pour gener les extensions jupyter
#$(JUPYTER_LABEXTENSIONS)/dask-labextension:
#	jupyter labextension install dask-labextension
$(JUPYTER_LABEXTENSIONS_DIR)/%:
	@echo -e "$(green)Install jupyter labextension $* $(normal)"
	jupyter labextension install $*

# ---------------------------------------------------------------------------------------
# SNIPPET pour gener les extensions jupyter
$(JUPYTER_LABEXTENSIONS)/%:
	jupyter labextension install $*

JUPYTER_EXTENSIONS:= $(JUPYTER_LABEXTENSIONS)/dask-labextension




# ---------------------------------------------------------------------------------------
# SNIPPET pour préparer l'environnement d'un projet juste après un `git clone`
.PHONY: configure
## Prepare the work environment (conda venv, kernel, ...)
configure:
	@conda create --name "$(VENV)" python=$(PYTHON_VERSION) -y $(CONDA_ARGS)
	@if [[ "base" == "$(CONDA_DEFAULT_ENV)" ]] || [[ -z "$(CONDA_DEFAULT_ENV)" ]] ; \
	then echo -e "Use: $(cyan)conda activate $(VENV)$(normal)" ; fi

# ---------------------------------------------------------------------------------------
.PHONY: remove-venv
remove-$(VENV):
	@$(DEACTIVATE_VENV)
	conda env remove --name "$(VENV)" -y 2>/dev/null
	echo -e "Use: $(cyan)conda deactivate$(normal)"
# Remove virtual environement
remove-venv : remove-$(VENV)

# ---------------------------------------------------------------------------------------
# SNIPPET de mise à jour des dernières versions des composants.
# Après validation, il est nécessaire de modifier les versions dans le fichier `setup.py`
# pour tenir compte des mises à jours
.PHONY: upgrade-venv
upgrade-$(VENV):
ifeq ($(OFFLINE),True)
	@echo -e "$(red)Can not upgrade virtual env in offline mode$(normal)"
else
	@$(VALIDATE_VENV)
	conda update --all $(CONDA_ARGS)
	pip list --format freeze --outdated | sed 's/(.*//g' | xargs -r -n1 pip install $(EXTRA_INDEX) -U
	@echo -e "$(cyan)After validation, upgrade the setup.py$(normal)"
endif
# Upgrade packages to last versions
upgrade-venv: upgrade-$(VENV)

# ---------------------------------------------------------------------------------------
# SNIPPET de validation des notebooks en les ré-executants.
# L'idée est d'avoir un sous répertoire par phase, dans le répertoire `notebooks`.
# Ainsi, il suffit d'un `make nb-run-phase1` pour valider tous les notesbooks du répertoire `notebooks/phase1`.
# Pour valider toutes les phases : `make nb-run-*`.
# L'ordre alphabétique est utilisé. Il est conseillé de préfixer chaque notebook d'un numéro.
.PHONY: nb-run-*
notebooks/.make-%: $(REQUIREMENTS) $(JUPYTER_DATA_DIR)/kernels/$(KERNEL)
	$(VALIDATE_VENV)
	time jupyter nbconvert \
	  --ExecutePreprocessor.timeout=-1 \
	  --execute \
	  --inplace notebooks/$*/*.ipynb
	date >notebooks/.make-$*
# All notebooks
notebooks/phases: $(sort $(subst notebooks/,notebooks/.make-,$(wildcard notebooks/*)))

## Invoke all notebooks in lexical order from notebooks/<% dir>
nb-run-%: $(JUPYTER_DATA_DIR)/kernels/$(KERNEL)
	VENV=$(VENV) $(MAKE) --no-print-directory notebooks/.make-$*


# ---------------------------------------------------------------------------------------
# SNIPPET de validation des scripts en les ré-executant.
# Ces scripts peuvent être la traduction de Notebook Jupyter, via la règle `make nb-convert`.
# L'idée est d'avoir un sous répertoire par phase, dans le répertoire `scripts`.
# Ainsi, il suffit d'un `make run-phase1` pour valider tous les scripts du répertoire `scripts/phase1`.
# Pour valider toutes les phases : `make run-*`.
# L'ordre alphabétique est utilisé. Il est conseillé de préfixer chaque script d'un numéro.
.PHONY: run-*
scripts/.make-%: $(REQUIREMENTS)
	$(VALIDATE_VENV)
	time ls scripts/$*/*.py | grep -v __ | sed 's/\.py//g; s/\//\./g' | \
		xargs -L 1 -t python -O -m
	@date >scripts/.make-$*

# All phases
scripts/phases: $(sort $(subst scripts/,scripts/.make-,$(wildcard scripts/*)))

## Invoke all script in lexical order from scripts/<% dir>
run-%:
	$(MAKE) --no-print-directory scripts/.make-$*

# ---------------------------------------------------------------------------------------
# SNIPPET pour valider le code avec flake8 et pylint
.PHONY: lint
.pylintrc:
	pylint --generate-rcfile > .pylintrc

.make-lint: $(REQUIREMENTS) $(PYTHON_SRC) | .pylintrc
	$(VALIDATE_VENV)
	@echo -e "$(cyan)Check lint...$(normal)"
	@echo "---------------------- FLAKE"
	@flake8 $(PRJ_PACKAGE)
	@echo "---------------------- PYLINT"
	@pylint $(PRJ_PACKAGE)
	touch .make-lint

## Lint the code
lint: .make-lint


# ---------------------------------------------------------------------------------------
# SNIPPET pour valider le typage avec pytype
$(CONDA_PREFIX)/bin/pytype:
	@pip install $(PIP_ARGS) -q pytype

pytype.cfg: $(CONDA_PREFIX)/bin/pytype
	@[[ ! -f pytype.cfg ]] && pytype --generate-config pytype.cfg || true
	touch pytype.cfg

.PHONY: typing
.make-typing: $(REQUIREMENTS) $(CONDA_PREFIX)/bin/pytype pytype.cfg $(PYTHON_SRC)
	$(VALIDATE_VENV)
	@echo -e "$(cyan)Check typing...$(normal)"
	# pytype
	pytype "$(PRJ)"
	for phase in scripts/*
	do
	  [[ -e "$$phase" ]] && ( cd $$phase && find -L . -type f -name '*.py' -exec pytype {} \; )
	done
	touch ".pytype/pyi/$(PRJ)"
	touch .make-typing

	# mypy
	# TODO: find Pandas stub
	# MYPYPATH=./stubs/ mypy "$(PRJ)"
	# touch .make-mypy

## Check python typing
typing: .make-typing

## Add infered typing in module
add-typing: typing
	@find -L "$(PRJ)" -type f -name '*.py' -exec merge-pyi -i {} .pytype/pyi/{}i \;
	for phase in scripts/*
	do
	  ( cd $$phase ; find -L . -type f -name '*.py' -exec merge-pyi -i {} .pytype/pyi/{}i \; )
	done



# ---------------------------------------------------------------------------------------
# SNIPPET pour créer un environnement 'make' dans un conteneur Docker.
.PHONY: docker-make-image docker-make-shell docker-make-clean
## Create a docker image to build the project with make
docker-make-image: docker/MakeDockerfile
	$(CHECK_DOCKER)
	echo -e "$(green)Build docker image '$(DOCKER_REPOSITORY)/$(PRJ)-make' to build the project...$(normal)"
	REPO=$(shell git remote get-url origin)
	echo "REPO=$$REPO"
	docker build \
		--build-arg UID=$$(id -u) \
		--build-arg REPO="$$REPO" \
		--build-arg BRANCH=develop \
		--tag $(DOCKER_REPOSITORY)/$(PRJ)-make \
		-f docker/MakeDockerfile .
	printf	"$(green)Declare\n$(cyan)alias dmake='docker run -v $$PWD:/$(PRJ) -it $(DOCKER_REPOSITORY)/$(PRJ)-make'$(normal)\n"
	@echo -e "$(green)and $(cyan)dmake ...  # Use make in a Docker container$(normal)"

## Start a shell to build the project in a docker container
docker-make-shell:
	@docker run --rm \
		-v $(PWD):/$(PRJ) \
		--group-add $$(getent group docker | cut -d: -f3) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(PWD):/$(PRJ) \

		--entrypoint $(SHELL) \
		-it $(DOCKER_REPOSITORY)/$(PRJ)-make

docker-make-clean:
	@docker image rm $(DOCKER_REPOSITORY)/$(PRJ)-make
	@echo -e "$(cyan)Docker image '$(DOCKER_REPOSITORY)/$(PRJ)-make' removed$(normal)"




# ---------------------------------------------------------------------------------------
# SNIPPET pour créer la documentation html et pdf du projet.
# Il est possible d'indiquer build/XXX, ou XXX correspond au type de format
# à produire. Par exemple: html, singlehtml, latexpdf, ...
# Voir https://www.sphinx-doc.org/en/master/usage/builders/index.html
.PHONY: docs
# Use all processors
#PPR SPHINX_FLAGS=-j$(NPROC)
SPHINX_FLAGS=
# Generate API docs
#PPR: Voir Mkdoc https://news.ycombinator.com/item?id=17717513
docs/source: $(REQUIREMENTS) $(PYTHON_SRC)
	$(VALIDATE_VENV)
	sphinx-apidoc -f -o docs/source $(PRJ)/
	touch docs/source

# Build the documentation in specificed format (build/html, build/latexpdf, ...)
build/%: $(REQUIREMENTS) docs/source docs/* *.md | .git
	@$(VALIDATE_VENV)
	@TARGET=$(*:build/%=%)
ifeq ($(OFFLINE),True)
	if [ "$$TARGET" != "linkcheck" ] ; then
endif
	@echo "Build $$TARGET..."
	@LATEXMKOPTS=-silent sphinx-build -M $$TARGET docs build $(SPHINX_FLAGS)
	touch build/$$TARGET
ifeq ($(OFFLINE),True)
	else
		@echo -e "$(red)Can not to build '$$TARGET' in offline mode$(normal)"
	fi
endif
# Build all format of documentations
## Generate and show the HTML documentation
docs: build/html
	@$(BROWSER) build/html/index.html


# ---------------------------------------------------------------------------------------
# SNIPPET pour créer une distribution des sources
.PHONY: sdist
dist/$(PRJ_PACKAGE)-*.tar.gz: $(REQUIREMENTS)
	@$(VALIDATE_VENV)
	python setup.py sdist

# Create a source distribution
sdist: dist/$(PRJ_PACKAGE)-*.tar.gz

# ---------------------------------------------------------------------------------------
# SNIPPET pour créer une distribution des binaires au format egg.
# Pour vérifier la version produite :
# python setup.py --version
# Cela correspond au dernier tag d'un format 'version'
.PHONY: bdist
dist/$(subst -,_,$(PRJ_PACKAGE))-*.whl: $(REQUIREMENTS) $(PYTHON_SRC)
	@$(VALIDATE_VENV)
	python setup.py bdist_wheel

# Create a binary wheel distribution
bdist: dist/$(subst -,_,$(PRJ_PACKAGE))-*.whl


# ---------------------------------------------------------------------------------------
# SNIPPET pour créer une distribution des binaires au format egg.
# Pour vérifier la version produite :
# python setup.py --version
# Cela correspond au dernier tag d'un format 'version'
.PHONY: dist

## Create a full distribution
dist: bdist sdist



# ---------------------------------------------------------------------------------------
# SNIPPET pour executer jupyter notebook, mais en s'assurant de la bonne application des dépendances.
# Utilisez `make notebook` à la place de `jupyter notebook`.
.PHONY: notebook
## Start jupyter notebooks
notebook: $(REQUIREMENTS) $(JUPYTER_DATA_DIR)/kernels/$(KERNEL) $(_JUPYTER_LABEXTENSIONS)
	@$(VALIDATE_VENV)
	DATA=$$DATA jupyter lab \
		--notebook-dir=notebooks \
		--ExecutePreprocessor.kernel_name=$(KERNEL)



# Download raw data if necessary
$(DATA)/raw:



# ---------------------------------------------------------------------------------------
# SNIPPET pour convertir tous les notebooks de 'notebooks/' en script
# python dans 'scripts/', déjà compatible avec le mode scientifique de PyCharm Pro.
# Le code utilise un modèle permettant d'encadrer les cellules Markdown dans des strings.
# Les scripts possèdent ensuite le flag d'exécution, pour pouvoir les lancer directement
# via un 'scripts/phase1/1_sample.py'.
.PHONY: nb-convert
# Convert all notebooks to python scripts
_nbconvert:  $(JUPYTER_DATA_DIR)/kernels/$(KERNEL)
	@echo -e "Convert all notebooks..."
	notebook_path=notebooks
	script_path=scripts
	tmpfile=$$(mktemp /tmp/make-XXXXX)

	cat >$${tmpfile} <<TEMPLATE
	{% extends 'python.tpl' %}
	{% block in_prompt %}# %%{% endblock in_prompt %}
	{%- block header -%}
	#!/usr/bin/env python
	# coding: utf-8
	{% endblock header %}
	{% block input %}
	{{ cell.source | ipython2python }}{% endblock input %}
	{% block markdowncell scoped %}
	# %% md
	"""
	{{ cell.source  }}
	"""
	{% endblock markdowncell %}
	TEMPLATE

	while IFS= read -r -d '' filename; do
		target=$$(echo $$filename | sed "s/^$${notebook_path}/$${script_path}/g; s/ipynb$$/py/g ; s/[ -]/_/g" )
		mkdir -p $$(dirname $${target})
		jupyter nbconvert --to python --ExecutePreprocessor.kernel_name=$(KERNEL) \
		  --template=$${tmpfile} --stdout "$${filename}" >"$${target}"
		chmod +x $${target}
		@echo -e "Convert $${filename} to $${target}"
	done < <(find -L notebooks -name '*.ipynb' -type f -not -path '*/\.*' -prune -print0)
	echo -e "$(cyan)All new scripts are in $${target}$(normal)"

# Version permettant de convertir les notebooks et de la ajouter en même temps à GIT
# en ajoutant le flag +x.
## Convert all notebooks to python scripts
nb-convert: _nbconvert
	@find -L scripts/ -type f -iname "*.py" -exec git add "{}" \;
	@find -L scripts/ -type f -iname "*.py" -exec git update-index --chmod=+x  "{}" \;

# ---------------------------------------------------------------------------------------
# SNIPPET pour nettoyer tous les fichiers générés par le compilateur Python.
.PHONY: clean-pyc
# Clean pre-compiled files
clean-pyc:
	@/usr/bin/find -L . -type f -name "*.py[co]" -delete
	@/usr/bin/find -L . -type d -name "__pycache__" -delete

# ---------------------------------------------------------------------------------------
# SNIPPET pour nettoyer les fichiers de builds (package et docs).
.PHONY: clean-build
# Remove build artifacts and docs
clean-build:
	@/usr/bin/find -L . -type f -name ".make-*" -delete
	@rm -fr build/ dist/* *.egg-info .repository
	@echo -e "$(cyan)Build cleaned$(normal)"

# ---------------------------------------------------------------------------------------
# SNIPPET pour nettoyer tous les notebooks
.PHONY: clean-notebooks
## Remove all results in notebooks
clean-notebooks: $(REQUIREMENTS)
	@[ -e notebooks ] && find -L notebooks -name '*.ipynb' -exec jupyter nbconvert --ClearOutputPreprocessor.enabled=True --inplace {} \;
	@echo -e "$(cyan)Notebooks cleaned$(normal)"

# ---------------------------------------------------------------------------------------
.PHONY: clean-pip
# Remove all the pip package
clean-pip:
	@$(VALIDATE_VENV)
	pip freeze | grep -v "^-e" | xargs pip uninstall -y
	@echo -e "$(cyan)Virtual env cleaned$(normal)"

# ---------------------------------------------------------------------------------------
# SNIPPET pour nettoyer complètement l'environnement Conda
.PHONY: clean-venv clean-$(VENV)
clean-$(VENV): remove-venv
	@conda create -y -q -n $(VENV) $(CONDA_ARGS)
	@touch setup.py
	@echo -e "$(yellow)Warning: Conda virtualenv $(VENV) is empty.$(normal)"
# Set the current VENV empty
clean-venv : clean-$(VENV)

# ---------------------------------------------------------------------------------------
# SNIPPET pour faire le ménage du projet (hors environnement)
.PHONY: clean
## Clean current environment
clean: clean-pyc clean-build clean-notebooks

# ---------------------------------------------------------------------------------------
# SNIPPET pour faire le ménage du projet
.PHONY: clean-all
# Clean all environments
clean-all: remove-kernel clean remove-venv docker-make-clean

# ---------------------------------------------------------------------------------------
# SNIPPET pour executer les tests unitaires et les tests fonctionnels.
# Utilisez 'NPROC=1 make unit-test' pour ne pas paralléliser les tests
# Voir https://setuptools.readthedocs.io/en/latest/setuptools.html#test-build-package-and-run-a-unittest-suite
ifeq ($(shell test $(NPROC) -gt 1; echo $$?),0)
PYTEST_ARGS ?=-n $(NPROC)  --dist loadgroup
else
PYTEST_ARGS ?=
endif
.PHONY: test unittest functionaltest
.make-unit-test: $(REQUIREMENTS) $(PYTHON_TST) $(PYTHON_SRC)
	@$(VALIDATE_VENV)
	@echo -e "$(cyan)Run unit tests...$(normal)"
	python -m pytest  -s tests $(PYTEST_ARGS) -m "not functional"
	@date >.make-unit-test
# Run only unit tests
unit-test: .make-unit-test

.PHONY: notebooks-test
_make-notebooks-test-%: $(REQUIREMENTS) $(PYTHON_TST) $(PYTHON_SRC) $(JUPYTER_DATA_DIR)/kernels/$(KERNEL) notebooks/demo.ipynb
	@$(VALIDATE_VENV)
	@echo -e "$(cyan)Run notebook tests for mode=$(VDF_MODE)...$(normal)"
	python $(PYTHON_PARAMS) -m papermill \
		-k $(KERNEL) \
		--log-level ERROR \
		--no-report-mode \
		notebooks/demo.ipynb \
		-p mode $(VDF_MODE) /dev/null
	@date >.make-notebooks-test-$*

## Run notebooks test with a specific *mode*
.PHONY: notebooks-test-*
notebooks-test-%: $(REQUIREMENTS)
	@VDF_MODE=$* $(MAKE) --no-print-directory _make-notebooks-test-$*

ifneq ($(USE_GPU),-gpu)
notebooks-test-cudf:
	@echo -e "$(red)Ignore VDF_MODE=cudf$(normal)"

notebooks-test-dask_cudf:
	@echo -e "$(red)Ignore VDF_MODE=dask_cudf$(normal)"
endif

.PHONY: notebooks-test-all
.make-notebooks-test: $(foreach ext,$(VDF_MODES),notebooks-test-$(ext))
	@date >.make-notebooks-test

## Run notebook test for all *mode*
notebooks-test: .make-notebooks-test

.make-functional-test: $(REQUIREMENTS) $(PYTHON_TST) $(PYTHON_SRC)
	@$(VALIDATE_VENV)
	@echo -e "$(cyan)Run functional tests...$(normal)"
	python -m pytest  -s tests $(PYTEST_ARGS) -m "functional"
	@date >.make-functional-test
# Run only functional tests
functional-test: .make-functional-test

.make-test: $(REQUIREMENTS) $(PYTHON_TST) $(PYTHON_SRC) .make-notebooks-test
	@echo -e "$(cyan)Run all tests...$(normal)"
	python -m pytest $(PYTEST_ARGS) -s tests
	#python setup.py test
	@date >.make-test
	@date >.make-unit-test
	@date >.make-functional-test
## Run all tests (unit and functional)
test: .make-test


# SNIPPET pour vérifier les TU et le recalcul de tout les notebooks et scripts.
# Cette règle est invoqué avant un commit sur la branche master de git.
.PHONY: validate
.make-validate: .make-test .make-typing $(DATA)/raw notebooks/*
	@date >.make-validate
## Validate the version before release
validate: .make-validate


## Install the tools in conda env
install: $(CONDA_PREFIX)/bin/$(PRJ)

## Install the tools in conda env with 'develop' link
develop:
	python setup.py develop

## Uninstall the tools from the conda env
uninstall: $(CONDA_PREFIX)/bin/$(PRJ)
	pip uninstall $(PRJ)


# Recette permettant un `make installer` pour générer un programme autonome comprennant le code et
# un interpreteur Python. Ainsi, il suffit de le copier et de l'exécuter sans pré-requis
# FIXME: Installer for Alpine ?
dist/$(PRJ)$(EXE): .make-validate
	@PYTHONOPTIMIZE=2 && pyinstaller $(PYINSTALLER_OPT) --onefile $(PRJ)/$(PRJ).py
	touch dist/$(PRJ)
ifeq ($(BACKOS),Windows)
# Must have conda installed on windows with tag_images_for_google_drive env
	/mnt/c/WINDOWS/system32/cmd.exe /C 'conda activate $(PRJ) && python setup.py develop && pyinstaller --onefile tag_images_for_google_drive/tag_images_for_google_drive.py'
	touch dist/$(PRJ).exe
	echo -e "$(cyan)Executable is here 'dist/$(PRJ).exe'$(normal)"
endif
ifeq ($(OS),Darwin)
	ln -f "dist/$(PRJ)" "dist/$(PRJ).macos"
	echo -e "$(cyan)Executable is here 'dist/$(PRJ).macos'$(normal)"
else
	echo -e "$(cyan)Executable is here 'dist/$(PRJ)'$(normal)"
endif

## Build standalone executable for this OS
installer: dist/$(PRJ)

## Publish the distribution in a local repository
local-repository:
	@pip install pypiserver || true
	mkdir -p .repository/$(PRJ)
	( cd .repository/$(PRJ) ; ln -fs ../../dist/*.whl . )
	echo -e "$(green)export PIP_EXTRA_INDEX_URL=http://localhost:8888/simple$(normal)"
	echo -e "or use $(green)pip install --index-url http://localhost:8888/simple/$(normal)"
	pypi-server -p 8888 .repository/


# Recette pour créer un Dockerfile.standalone avec la version du projet.
# Modifiez le code du directement ici.
Dockerfile.standalone: setup.py
	@# Build docker file with setup parameters
	VERSION="$$(./setup.py --version)"
	DESCRIPTION="$$(./setup.py --description)"
	LICENSE="$$(./setup.py --license)"
	AUTHOR="$$(./setup.py --author)"
	AUTHOR_EMAIL="$$(./setup.py --author-email)"
	KEYWORDS="$$(./setup.py --keywords)"
	D='$$'

	cat >Dockerfile.standalone <<EOF
	# DO NOT ADD THIS FILE TO VERSION CONTROL!
	ARG OS_VERSION=latest
	FROM alpine:$${D}{OS_VERSION}

	LABEL version="$${VERSION}"
	LABEL description="$${DESCRIPTION}"
	LABEL license="$${LICENSE}"
	LABEL keywords="$${KEYWORDS}"
	LABEL maintainer="$${AUTHOR}"

	ENV LANG=C.UTF-8
	ENV LC_ALL=C.UTF-8
	WORKDIR /data
	COPY dist/$(PRJ) /usr/local/bin
	ENTRYPOINT [ "/usr/local/bin/$(PRJ)" ]
	# TODO: update parameters
	CMD [ "--help" ]
	EOF

.make-docker-build: Dockerfile.standalone dist/$(PRJ)$(EXE)
	@# Detect release version
	if [[ "$${VERSION}" =~ "^[0-9](\.[0-9])+$$" ]];
	then
		TAG_VERSION=-t "$(DOCKER_REPOSITORY)/$(PRJ):$${VERSION}"
	fi
	$(SUDO) docker build \
		-f Dockerfile.standalone \
		--build-arg OS_VERSION="latest" \
		$${TAG_VERSION} \
		-t "$(DOCKER_REPOSITORY)/$(PRJ):latest" .
	date >.make-docker-build

## Build the docker <PRJ>:latest
docker-build: .make-docker-build

# Reset and rebuild the container
docker-rebuild:
	@rm -f Dockerfile.standalone .make-docker-build
	$(MAKE) --no-print-directory docker-stop docker-start

# Create a dedicated volume
docker-volume:
	@$(SUDO) docker volume inspect "$(PRJ)" >/dev/null 2>&1 || \
	$(SUDO) docker volume create --name "$(PRJ)"
	echo -e "$(cyan)Docker volume '$(PRJ)' created$(normal)"

.cid_docker_daemon: .make-docker-build
	$(SUDO) docker volume inspect "$(PRJ)" >/dev/null 2>&1 || $(MAKE) --no-print-directory docker-volume
	# Remove --detach if it's not a daemon
	$(SUDO) docker run \
		--detach \
		--cidfile ".cid_docker_daemon" \
		-v $(PRJ):/data \
		-it "$(DOCKER_REPOSITORY)/$(PRJ):latest"
	echo -e "$(cyan)Docker daemon started$(normal)"

# Start and attach the container
docker-run: .cid_docker_daemon docker-attach

## Start a daemon container with the docker image
docker-start: .cid_docker_daemon

## Attach to the docker
docker-attach: .cid_docker_daemon
	@CID=$$(cat .cid_docker_daemon)
	$(SUDO) docker attach "$${CID}"

## Connect a bash in the container
docker-bash: .cid_docker_daemon
	@CID=$$(cat .cid_docker_daemon)
	$(SUDO) docker exec -i -t "$${CID}" /bin/bash

## Stop the container daemon
docker-stop:
	@if [[ -e ".cid_docker_daemon" ]] ; then
		CID=$$(cat .cid_docker_daemon)
		$(SUDO) docker stop "$${CID}" || true
		rm -f .cid_docker_daemon
		echo -e "$(cyan)Docker daemon stopped$(normal)"
	fi

docker-logs: .cid_docker_daemon
	@$(SUDO) docker container logs -f "$(PRJ)"

docker-top: .cid_docker_daemon
	@$(SUDO) docker container top "$(PRJ)"

## Run the projet
run: $(REQUIREMENTS)
	PYTHONPATH=.:virtual_dataframe:pandera python -m $(PRJ).$(PRJ)
