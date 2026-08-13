import requests
from dotenv import load_dotenv
import os
from logger import setup_logging
import pandas as pd

logger = setup_logging()

parent_dir = os.path.dirname(os.path.dirname(__file__))
load_dotenv(os.path.join(parent_dir, '.env'))

API_URL = os.getenv('API_URL')

def get_data(target_date):
    if not API_URL:
        raise ValueError('Переменная API_URL не найдена в .env')
    try:
        response = requests.get(API_URL, params = {'date':target_date}, timeout=30)
        logger.info(f'Дата:{target_date}, HTTP статус: {response.status_code}')
        response.raise_for_status()
        data = response.json()
    except requests.exceptions.RequestException:
            logger.exception(f'Ошибка запроса за дату {target_date}')
            raise
    if not isinstance(data, list):
         raise ValueError(f'За {target_date} API вернул неожиданный тип: {type(data).__name__}')

    df = pd.DataFrame(data)
    logger.info(f'За {target_date} получено строк: {len(df)}')
    return df
    

