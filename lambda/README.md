# AWS Lambda: S3 Bucket event -> CloudFront Invalidation 

When an index* file is created/updated on a S3 bucket, this NodeJS based AWS lambda function finds a distribution that uses the bucket as a origin and creates a [wildcard](https://aws.amazon.com/about-aws/whats-new/2015/05/amazon-cloudfront-makes-it-easier-to-invalidate-multiple-objects/) parametrized CloudFront Invalidation.

Installation
=======================

If you are not using [apex](http://apex.run/) or [serverless](http://www.serverless.com/) to manage AWS Lambda functions you can install it by:

1. Installing the dependencies

       npm install
       
2. Zip it and upload the whole zip to AWS Lambda.


3. Create the role for the AWS lambda. For CloudFront the next role policy:
 
         {
             "Version": "2012-10-17",
             "Statement": [
                 {
                     "Effect": "Allow",
                     "Action": [
                         "cloudfront:CreateInvalidation",
                         "cloudfront:ListDistributions",
                         "cloudfront:ListDistributionsByWebACLId",
                         "cloudfront:ListInvalidations"
                     ],
                     "Resource": [
                         "*"
                     ]
                 }
             ]
         }
 
 And for S3 and logging the role policy:
 
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents"
                    ],
                    "Resource": "arn:aws:logs:*:*:*"
                },
                {
                    "Effect": "Allow",
                    "Action": [
                        "s3:GetObject",
                        "s3:PutObject"
                    ],
                    "Resource": [
                        "arn:aws:s3:::*"
                    ]
                }
            ]
        }


4. The handler

        s3-bucket-cf-invalidation.handler


5. For the event source, select the S3 bucket(s) related.
 

Based on this [gist](https://gist.github.com/supinf/e66fd36f9228a8701706
) by [supinf](https://github.com/supinf)