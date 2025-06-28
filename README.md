# Brulion - a Trello clone in Whelk

This is a REST API written in Perl. It uses [Whelk](https://metacpan.org/pod/Whelk).

## Frontend

A web application frontend is developed in [a separate repository](https://github.com/bbrtj/pascal-brulion).

## Setting up

This application requires Perl 5.40 with an ability to install CPAN modules and a sqlite library installed in the system.

```
cpanm Carmel App::Sqitch
sqitch deploy brulion_db
carmel install
carmel exec plackup
```

