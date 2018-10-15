# routine-nanopore-analysis

A set of scripts to support routine processing of Oxford Nanopore MinION sequence data on a Sun GridEngine-based HPC cluster.

## Getting Started

### Prepare conda environments

It is expected that several bioinformatics tools are provided as tool-specific conda environments. Each environment is activated in turn by calling:

```
source activate <tool-version>
```

...and deactivated by calling:

```
source deactivate
```

In order for this to work, a conda installation must be available on the user's `PATH`.

If these environments are not already available on your system, create them as follows:

```
conda create -n <tool-version> tool=version
```

For example:

```
conda create -n mash-2.0 mash=2.0
```

### Edit the `config.conf` file

A [config.conf](config.conf) file is used to customize these scripts to a specific system. Review that file and fill in appropriate values for those settings before running these scripts.
