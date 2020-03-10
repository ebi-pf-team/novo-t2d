# novo-t2d

Populating database for Novo Nordisk.

## Requirements

The `populate.py` script requires Python 3 with the `pymysql` and `requests` packages.

## How to run

Set the following environment variables to specify the MySQL database connection information:

```
# Name of host to connect to
export NND_HOST=...

# User to authenticate to
export NND_USER=...

# Password to authenticate with
export NND_PASS=...

# Port of MySQL server
export NND_PORT=...

# Database to use
export NND_DB=...
```

Then, run the script:

```
python populate.py [-t/--threads THREADS] [--debug]
``` 

Options:

* `-t/--threads`: maximum number of parallel threads used to call the InterPro REST API (default: 4).
* `--verbose`: increase verbosity by showing progress.

