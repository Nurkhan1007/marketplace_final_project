import os
from sqlalchemy import create_engine, URL, text
from dotenv import load_dotenv
from logger import setup_logging
import pandas as pd

parent_dir = os.path.dirname(os.path.dirname(__file__))
load_dotenv(os.path.join(parent_dir, '.env'))

logger = setup_logging()

class PostgreSQLLoader:
    def __init__(self):
        self.host = os.getenv('host')
        self.port = os.getenv('port')
        self.database = os.getenv('dbname')
        self.user = os.getenv('user')
        self.password = os.getenv('password')
        self.engine = self.create_db_engine()

    def create_db_engine(self):
        connection_url = URL.create(
            drivername = 'postgresql+psycopg2',
            username = self.user,
            password = self.password,
            host = self.host,
            port = int(self.port),
            database = self.database,
        )
        engine = create_engine(connection_url, pool_pre_ping=True)

        
        return engine
    def load_dataframe(self, df:pd.DataFrame, table_name='sales', schema='raw'):
        try:
            with self.engine.begin() as connection:
                logger.info(f'Соединение с базой данных {self.database} успешно установлено')
                df.to_sql(
                    name = table_name,
                    con = connection,
                    schema = schema,
                    if_exists = 'append',
                    index=False,
                    method='multi',
                    chunksize=5000
                )
            logger.info(f'Загружено в {schema}.{table_name} {len(df)} строк.')
        except Exception as e:
            logger.error(f'Ошибка загрузки в {schema}.{table_name}: {e}')
            raise

    def date_exists(self, target_date, table_name='sales', schema='raw'):
        query = text(
            f'''SELECT EXISTS (
            SELECT 1
            FROM {schema}.{table_name}
            WHERE purchase_date=:target_date)'''
        )
        try:
            with self.engine.connect() as connection:
                result = connection.execute(query, {'target_date':target_date}).scalar()
            return bool(result)
        except Exception:
            logger.exception(f'Ошибка проверки данных за дату: {target_date}')
            raise

    def refresh_materialized_views(self):
        materialized_views = (
            'analytics.mv_daily_sales',
            'analytics.mv_customer_rfm',
            'analytics.mv_product_monthly_sales',
            'analytics.mv_product_abc_xyz',
        )

        try:
            with self.engine.connect() as connection:
                autocommit_connection = connection.execution_options(
                    isolation_level='AUTOCOMMIT'
                )

                for view_name in materialized_views:
                    logger.info(
                        f'Начато обновление витрины {view_name}'
                    )

                    autocommit_connection.execute(
                        text(
                            'REFRESH MATERIALIZED VIEW '
                            f'CONCURRENTLY {view_name}'
                        )
                    )

                    logger.info(
                        f'Витрина {view_name} успешно обновлена'
                    )

        except Exception:
            logger.exception(
                'Ошибка обновления аналитических витрин'
            )
            raise

    def close(self):
        self.engine.dispose()
        logger.info(f'Соединение с {self.database} закрыто')

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()