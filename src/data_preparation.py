from api_client import get_data
import pandas as pd

required_columns = ['client_id', 'gender', 'purchase_datetime', 'purchase_time_as_seconds_from_midnight', 
                    'product_id', 'quantity', 'price_per_item', 'discount_per_item', 'total_price']

output_columns = ['client_id', 'gender', 'purchase_date', 'purchase_time_seconds', 
                  'product_id', 'quantity', 'price_per_item', 'discount_per_item', 'total_price']


def prepare_data(df: pd.DataFrame, expected_date):
    if df.empty:
        raise ValueError(f'За {expected_date} получен пустой DataFrame')
    missing_columns = set(required_columns) - set(df.columns)

    if missing_columns:
        raise ValueError(f'Отсутствуют обязательные столбцы: {missing_columns}')
    prepared_df = df.copy()

    prepared_df = prepared_df.rename(columns={'purchase_datetime':'purchase_date', 'purchase_time_as_seconds_from_midnight':'purchase_time_seconds'})

    prepared_df['purchase_date'] = pd.to_datetime(prepared_df['purchase_date'], errors='raise').dt.date

    integer_columns = ['purchase_time_seconds', 'quantity']

    for column in integer_columns:
        prepared_df[column] = pd.to_numeric(prepared_df[column], errors='raise').astype('int64')

    decimal_columns = ['price_per_item', 'discount_per_item', 'total_price']

    for column in decimal_columns:
        prepared_df[column] = pd.to_numeric(prepared_df[column], errors='raise').round(2)

    if not prepared_df['purchase_date'].eq(expected_date).all:
        raise ValueError(f'В данных есть даты, отличные от {expected_date}')

    invalid_time = ((prepared_df['purchase_time_seconds']<0)|(prepared_df['purchase_time_seconds']>=86490))

    if invalid_time.any():
        raise ValueError(f'Обнаружено строк с некорректным временем: {invalid_time.sum()}')

    expected_total = (prepared_df['quantity']*(prepared_df['price_per_item'] - prepared_df['discount_per_item'])).round(2)

    invalid_total = ~prepared_df['total_price'].eq(expected_total)

    if invalid_total.any():
        raise ValueError(f'Обнаружено строк с неверным total_price: {invalid_total.sum()}')

    return prepared_df[output_columns]


     



