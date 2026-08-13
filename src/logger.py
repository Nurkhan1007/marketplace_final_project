import logging
import datetime
import os

parent_dir = os.path.dirname(os.path.dirname(__file__))
logs_dir = os.path.join(parent_dir, 'logs')

def cleanup_logs():
    if not os.path.exists(logs_dir):
        return
    now = datetime.datetime.now()
    for filename in os.listdir(logs_dir):
        file_path = os.path.join(logs_dir, filename)
        if not os.path.isfile(file_path):
            continue
        try:
            file_date_str = filename.replace('.log', '')
            file_date = datetime.datetime.strptime(file_date_str, '%Y-%m-%d')
            if (now - file_date) > datetime.timedelta(days=7):
                os.remove(file_path)
                logging.info(f"Удален старый лог-файл: {file_path}")
        except Exception as e:
            logging.error(f"Ошибка при удалении лог-файла {file_path}: {e}")
            continue

def setup_logging():
    os.makedirs(logs_dir, exist_ok=True)
    filename = os.path.join(logs_dir, f"{datetime.datetime.now().strftime('%Y-%m-%d')}.log")
    logging.basicConfig(
        filename=filename,
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(name)s%(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    return logging.getLogger(__name__)