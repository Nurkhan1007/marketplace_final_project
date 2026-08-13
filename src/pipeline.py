from datetime import date

from api_client import get_data
from data_preparation import prepare_data
from logger import setup_logging

logger = setup_logging()

def process_data(target_date:date, loader) -> int:
    logger.info(f'Начало обработки даты: {target_date}')

    if loader.date_exists(target_date=target_date, table_name='sales', schema='raw'):
        logger.warning(f'Данные за {target_date} уже существуют в raw.sales. Загрузка пропущена')
        return 0

    raw_df = get_data(target_date)

    prepared_df = prepare_data(df=raw_df, expected_date=target_date)

    loader.load_dataframe(df=prepared_df, table_name = 'sales', schema='raw')

    rows_loaded = len(prepared_df)

    logger.info(f'Дата {target_date} успешно обработана. Загружено строк: {rows_loaded}')

    return rows_loaded
