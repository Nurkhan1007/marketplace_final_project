from datetime import date, timedelta

from logger import setup_logging
from pipeline import process_data
from database import PostgreSQLLoader

logger = setup_logging()

def main():
    target_date = date.today() - timedelta(days=1)

    logger.info(f'Запуск ежедневной загрузки за {target_date}')

    try:
        with PostgreSQLLoader() as loader:
            rows_loaded = process_data(target_date = target_date, loader=loader)

        if rows_loaded == 0:
            logger.info(f'Данные за {target_date} уже существуют. Новые строки не загружены')
        else:
            logger.info(f'Ежедневная загрузка завершена. За {target_date} загружено: {rows_loaded}')
    except  Exception:
        logger.exception(f'Ежедневная загрузка за {target_date} завершилась ошибкой')
        raise

if __name__ == '__main__':
    main()