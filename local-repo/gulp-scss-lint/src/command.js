'use strict';

var Promise = require('bluebird');
var checkstyle = require('./checkstyle');
var dargs = require('dargs');
var child_process = require('child_process');

var scssLintCodes = {
  '64': 'Command line usage error',
  '66': 'Input file did not exist or was not readable',
  '69': 'You need to have the scss_lint_reporter_checkstyle gem installed',
  '70': 'Internal software error',
  '78': 'Configuration error',
  '127': 'You need to have Ruby and scss-lint gem installed'
};

function generateCommandParts(filePaths, options) {
  var commandParts = ['scss-lint'];
  var excludes = [
    'bundleExec',
    'filePipeOutput',
    'reporterOutput',
    'endlessReporter',
    'src',
    'shell',
    'reporterOutputFormat',
    'customReport',
    'maxBuffer',
    'endless',
    'verbose',
    'sync'
  ];

  if (options.bundleExec) {
    commandParts.unshift('bundle', 'exec');
    excludes.push('bundleExec');
  }

  var optionsArgs = dargs(options, { excludes: excludes });
  return commandParts.concat(filePaths, optionsArgs);
}

function execCommand(commandParts, options) {
  return new Promise(function(resolve, reject) {
    var commandOptions = {
      env: process.env,
      cwd: process.cwd(),
      maxBuffer: options.maxBuffer || 300 * 1024
    };

    const process = child_process.spawn(commandParts[0], commandParts.slice(1), commandOptions);
    let stdout = '';
    let stderr = '';

    process.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    process.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    process.on('close', (code) => {
      if (code === 0) {
        resolve({ error: null, report: stdout });
      } else {
        resolve({ error: { code: code, message: stderr }, report: stdout });
      }
    });

    process.on('error', (error) => {
      reject(error);
    });
  });
}

function configFileReadError(report, options) {
  var re = new RegExp('No such file or directory(.*)' + options.config, 'g');
  return re.test(report);
}

function execLintCommand(commandParts, options) {
  return new Promise(function(resolve, reject) {
    execCommand(commandParts, options).then(function(result) {
      var error = result.error;
      var report = result.report;

      if (error && error.code !== 1 && error.code !== 2 && error.code !== 65) {
        if (scssLintCodes[error.code]) {
          if (error.code === 66 && configFileReadError(report, options)) {
            reject('Config file did not exist or was not readable');
          } else {
            reject(scssLintCodes[error.code]);
          }
        } else if (error.code) {
          reject('Error code ' + error.code + '\n' + error.message);
        } else {
          reject(error.message);
        }
      } else if (error && error.code === 1 && report.length === 0) {
        reject('Error code ' + error.code + '\n' + error.message);
      } else {
        if (options.format === 'JSON') {
          resolve([JSON.parse(report)]);
        } else {
          checkstyle.toJSON(report, resolve);
        }
      }
    });
  });
}

module.exports = function(filePaths, options) {
  var commandParts = generateCommandParts(filePaths, options);

  if (options.verbose) {
    console.log(commandParts.join(' '));
  }

  return execLintCommand(commandParts, options);
};
