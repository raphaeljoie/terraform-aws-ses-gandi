import boto3
import json
import logging
from email.parser import BytesParser
from email import policy
import os


s3_client = boto3.client("s3")


class ByteHolder:
    def __init__(self, content):
        self.content = content

    def read(self, *args, **kwargs):
        return self.content


def lambda_handler(event, context):
    try:
        ses_mail = event['Records'][0]['ses']['mail']
        receipt = event['Records'][0]['ses']['receipt']
        message_id = ses_mail['messageId']
        print('Commencing processing for message {}'.format(message_id))

        statuses = [
            receipt['spamVerdict']['status'],
            receipt['virusVerdict']['status'],
            receipt['spfVerdict']['status'],
            receipt['dkimVerdict']['status']
        ]

        if 'FAIL' in statuses:
            raise Exception('Message failed to pass the appropriate security checks - ceasing processing of message.')

        s3 = boto3.resource('s3')
        bucket = s3.Bucket('bucketname')
        raw_email = bucket.Object(message_id).get()['Body'].read()
        msg = BytesParser(policy=policy.SMTP).parsebytes(raw_email)

        for attachment in msg.iter_attachments():
            fn = attachment.get_filename()
            ct = attachment.get_content_type()
            print(f'Attachment filename is "{fn}" and content type is "{ct}"')
            if fn:
                extension = os.path.splitext(attachment.get_filename())[1]
            else:
                extension = mimetypes.guess_extension(attachment.get_content_type())
            data = attachment.get_content()
            bucket.upload_fileobj(ByteHolder(data), f'{message_id}/{fn}')

        plain = ''
        try:
            plain = msg.get_body(preferencelist=('plain'))
            plain = ''.join(plain.get_content().splitlines(keepends=True))
            plain = '' if plain == None else plain
        except:
            print('Incoming message does not have an plain text part - skipping this part.')

        html = ''
        try:
            html = msg.get_body(preferencelist=('html'))
            html = ''.join(html.get_content().splitlines(keepends=True))
            html = '' if html == None else html
        except:
            print('Incoming message does not have an HTML part - skipping this part.')

        try:
            # delete the S3 object if you don't need it anymore?
            pass
        except:
            # some error you care about
            pass
    except Exception as e:
        # do whatever you need to do
        raise e
