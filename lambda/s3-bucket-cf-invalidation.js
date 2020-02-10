/**
 * When an index.html is created/updated on a bucket: Finds a distribution that uses the bucket as a origin. and creates a parametrized CloudFront Invalidation
 */
console.log('S3 bucket -> CloudFront action : Loading event');
var Q = require('q');
var aws = require('aws-sdk');
var cloudfront = new aws.CloudFront();

/**
 * The Event
 */
exports.handler = function (event, context) {

  console.log('Got event: ' + JSON.stringify(event, true, '  '));

  var bucketName = event.Records[0].s3.bucket.name;
  console.log('S3 Bucket affected: ' + bucketName);

  var theFile = event.Records[0].s3.object.key;
  console.log('Object changed: ' + theFile);

  // Trigger the invalidation just when the index file is changed
  if (theFile.indexOf('index') > -1) {

    // Creates the invalidation for the distribution that uses the bucket as a origin.
    function createInvalidation(params, deferred) {
      cloudfront.createInvalidation(params, function (error, data) {
        if (error) {
          console.log('Got error creating the invalidation: ' + JSON.stringify(error, true, '  '));
          deferred.reject();
          return;
        }
        console.log('Success: ' + JSON.stringify(data.InvalidationBatch, true, '  '));
        deferred.resolve();
      });
    }

    // Returns the parameter with the item affected for the invalidation
    function buildInvalidationParameter(distribution) {
      return {
        DistributionId: distribution.Id,
        InvalidationBatch: {
          CallerReference: '' + new Date().getTime(),
          Paths: {
            Quantity: 1,
            Items: ['/*']
          }
        }
      };
    }

    //Required policy, see README
    cloudfront.listDistributions({}, function (error, data) {
      var promises = [];
      if (error) {
        console.log('Error listing the CloudFront Distribution: ' + JSON.stringify(error, true, '  '));
        context.done('error', error);
        return;
      }

      data.Items.map(function (distribution) {
        var deferred = Q.defer();
        var exists = false;

        distribution.Origins.Items.map(function (origin) {
          if (exists) {
            return;
          }

          if (0 === origin.DomainName.indexOf(bucketName)) {
            exists = true;
            var name = distribution.DomainName;
            if (distribution.Aliases.Quantity > 0) {
              name = distribution.Aliases.Items[0];
            }
            console.log('Distribution: ' + distribution.Id + ' (' + name + ')');

            // Parameters for a invalidation
            var param = buildInvalidationParameter(distribution);
            console.log('Parameter : ' + JSON.stringify(param, true, '  '));

            // Creates the Invalidation
            createInvalidation(param, deferred);
          }
        });
        if (!exists) {
          deferred.resolve();
        }
        promises.push(deferred.promise);
      });
      //Executes the promises
      Q.all(promises).then(function () {
        context.done(null, '');
      });
    });
  } else {
    console.log('The invalidation is triggered for the "index*" files, not for the file: ' + theFile);
  }
};
