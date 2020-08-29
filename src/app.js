var createError = require('http-errors');
var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
var fs = require('fs');
var https = require('https');

var indexRouter = require('./routes/index');
var usersRouter = require('./routes/users');

const httpsport = 8443;
const mtlsport = 8444;
const host = '0.0.0.0';

var options = {
  cert: fs.readFileSync('./certs/webcert.pem'),
  key: fs.readFileSync('./certs/webcert.key')
};

var app = express();
var appmtls = express();

var httpsserver = https.createServer(options, app).listen(httpsport, host, function(){
  console.log("Express server 1 listening on port " + httpsport);
});

var mtlssserver = https.createServer(
  {
    cert: fs.readFileSync('./certs/webcert.pem'),
    key: fs.readFileSync('./certs/webcert.key'),
    ca: fs.readFileSync('./certs/ca-int-contoso.crt'),
    requestCert: true,
    rejectUnauthorized: false
  },
  appmtls).listen(mtlsport, host, function(){
    console.log("Express server 2 (mtls) listening on port " + mtlsport);
  }
);

appmtls.get('/', (req, res) => {
  if (!req.client.authorized) {
    res.writeHead(401);
    res.end('Invalid client certificate');
  }
  res.writeHead(200).send('hello');
});

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', indexRouter);
app.use('/users', usersRouter);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

// module.exports = app;
module.exports = { app, appmtls }
