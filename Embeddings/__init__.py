import logging

import azure.functions as func
import json
import openai
from openai.embeddings_utils import get_embedding
from langchain.embeddings import OpenAIEmbeddings
from langchain.text_splitter import TokenTextSplitter
import pandas as pd
import re
import time
import os

def text_split_embedd(relevant_data):
    text_splitter = TokenTextSplitter(chunk_size=2000, chunk_overlap=0)
    texts = text_splitter.split_text(relevant_data)
    df = pd.DataFrame(texts, columns =['text'])

    engine = os.getenv['TEXT_EMBEDDING_MODEL']
    start = 0
    df_result = pd.DataFrame()
    for i, g in df.groupby(df.index // 1):
        try:
            logging.info(g)
            logging.info(type(g))
            logging.info('_' * 15)
            g['curie_search'] = g["text"].apply(lambda x : get_embedding(x, engine =  engine))

            df_result = pd.concat([df_result,g], axis=0)

        except Exception as e:
            logging.info(e)
            logging.info('Error in get_embedding')
            continue
        finally:
            logging.info('finally')
            continue

    df_result
    logging.info(len(df_result))

    embeddings = []
    data = []

    for index, row in df_result.iterrows():
        embeddings.append(row['curie_search'])
        data.append(row['text'])

    return data, embeddings


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        body = json.dumps(req.get_json())
    except ValueError:
        return func.HttpResponse(
             "Invalid body",
             status_code=400
        )
    
    if body:
        result = compose_response(body)
        return func.HttpResponse(result, mimetype="application/json")
    else:
        return func.HttpResponse(
             "Invalid body",
             status_code=400
        )
    
def compose_response(json_data):
    logging.info('compose response')
    values = json.loads(json_data)['values']

    results = {}
    results["values"] = []

    for value in values:
        logging.info('about to transform value')
        outputRecord = transform_value(value)
        if outputRecord != None:
            results["values"].append(outputRecord)
    # Keeping the original accentuation with ensure_ascii=False

    logging.info('**************************')
    logging.info('results')
    logging.info(results)
    return json.dumps(results, ensure_ascii=False)

def transform_value(value):
    try:
        recordId = value['recordId']
    except AssertionError  as error:
        return None

    # Validate the inputs
    try:         
        assert ('data' in value), "'data' field is required."
        data = value['data']        
        assert ('text' in data), "'text' field is required in 'data' object."
    except AssertionError  as error:
        return (
            {
            "recordId": recordId,
            "data":{},
            "errors": [ { "message": "Error:" + error.args[0] }   ]
            })

    try:                
        # Getting the items from the values/data/text
        logging.info('getting text data')
        searchresults = value['data']['text']
        logging.info(searchresults)


        API_BASE = os.environ["API_BASE"]
        API_KEY = os.environ["API_KEY"]
        API_VERSION = os.environ["API_VERSION"]
        API_TYPE = os.environ["API_TYPE"]

        openai.api_type = API_TYPE
        openai.api_base = API_BASE
        openai.api_version = API_VERSION
        openai.api_key  = API_KEY
        
        data, embeddings = text_split_embedd(searchresults)

        logging.info('**********data********************')
        logging.info(data)

        logging.info('**********embeddings********************')
        logging.info(embeddings)
    except:
        return (
            {
            "recordId": recordId,
            "errors": [ { "message": "Could not complete operation for record." }   ]
            })

    return ({
            "recordId": recordId,
            "data": {
                "embeddings_text": data,
                "embeddings": embeddings
                    }
            })
