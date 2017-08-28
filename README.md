Timesketch docker-compose
-------------------------

## Usage

The usage is dead simple:

```
git clone https://github.com/ilyaglow/docker-timesketch
docker-compose up -d
```

### Add user

```
docker-compose exec timesketch tsctl add_user -u username -p thepassphrase
```

See more info on the [official github repo](https://github.com/google/timesketch)
