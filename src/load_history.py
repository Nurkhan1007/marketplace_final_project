from datetime import date, timedelta

from logger import setup_logging
from pipeline import process_data
from database import PostgreSQLLoader

logger = setup_logging()

start_date = date(2022, 1, 1)
end_date = date.today() - timedelta(days=1)

def load_history():
    current_date = start_date
    loaded_days = 0
    skipped_days = 0
    total_rows = 0
    failed_dates = []

    logger.info(f'Начало исторической загрузки: {start_date} - {end_date}')

    with PostgreSQLLoader() as loader:
        while current_date <= end_date:
            try:
                rows_loaded = process_data(target_date=current_date, loader = loader)

                if rows_loaded == 0:
                    skipped_days += 1
                else:
                    loaded_days += 1
                    total_rows += rows_loaded
            except Exception:
                failed_dates.append(current_date)
                logger.exception(f'Ошибка обработки даты {current_date}. Переходим к следующей дате')

            current_date += timedelta(days=1) 

    logger.info(f'Историческа загрузка завершена. Загружено дней: {loaded_days}. Пропущено дней: {skipped_days}. Дней с ошибками: {len(failed_dates)}. Загружено строк: {total_rows}')

if __name__ == "__main__":
    load_history()