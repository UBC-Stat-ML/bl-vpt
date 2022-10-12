# Variational PT plug-in for Blang

This repository contains the Blang code accompanying the paper
"Parallel Tempering With a Variational Reference" by Surjanovic, Syed, Bouchard-Côté, and Campbell. NeurIPS (2022).
[https://arxiv.org/abs/2206.00080](https://arxiv.org/abs/2206.00080)

### Required software

- bash
- the following should be available in the PATH variable:
    - Java Open SDK, version **11** (use [sdkman](https://sdkman.io/))
    - Rscript
- the following R packages should be installed:
    - ggplot2
    - dplyr
    - ggridges


### Compiling

```
cd bl-vpt
./gradlew installDist
```


### Running the stabilized moment matching on one model

Still from the ``bl-vpt`` folder:

```
chmod 755 pt-matching.sh
./pt-matching.sh --model ptbm.models.ToyMix
```

To see available options, use ``./pt-matching.sh --model ptbm.models.ToyMix --help``

To find other existing available models, use ``ls src/main/java/ptbm/models/``


### Adding a new model

- You can base your new model on one of the models in ``bl-vpt/src/main/java/ptbm/models/``
- Implement the model based off the [Blang documentation](https://arxiv.org/pdf/1912.10396.pdf) with the following amendments:
    - For each latent random variable that you would like to approach variationally, enclose the distribution declaration with ``Opt``, and pass in the target distribution as argument as in the following example: ``mu ~ Normal(0.0, 1.0)`` becomes ``mu ~ Opt(Normal::distribution(0.0, 1.0))``
    - Declare the type of such random variable as ``VariationalReal`` instead of ``RealVar``.
- Then follow the compilation instructions above.
