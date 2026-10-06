"""Independently reproduce README results from the CSV; requires pandas."""
from pathlib import Path
import json
import pandas as pd
ROOT=Path(__file__).resolve().parent
raw=pd.read_csv(ROOT/'SQL - Retail Sales Analysis_utf .csv').rename(columns={'quantiy':'quantity'})
assert raw.transactions_id.is_unique
clean=raw.dropna(subset=list(raw.columns)).copy()
clean['sale_date']=pd.to_datetime(clean.sale_date)
summary={'raw_rows':len(raw),'clean_rows':len(clean),'excluded_rows':len(raw)-len(clean),'unique_customers':int(clean.customer_id.nunique()),'date_from':str(clean.sale_date.min().date()),'date_to':str(clean.sale_date.max().date()),'total_sales':float(clean.total_sale.sum()),'nulls_by_column':raw.isna().sum().to_dict()}
outputs={}
outputs['category_sales']=clean.groupby('category').agg(total_sales=('total_sale','sum'),total_orders=('transactions_id','size')).sort_values('total_sales',ascending=False)
monthly=clean.groupby([clean.sale_date.dt.year.rename('year'),clean.sale_date.dt.month.rename('month')]).total_sale.mean().rename('average_sale').reset_index()
outputs['best_average_month']=monthly[monthly.groupby('year').average_sale.rank(method='min',ascending=False).eq(1)].set_index('year')
outputs['top_customers']=clean.groupby('customer_id').total_sale.sum().rename('total_sales').reset_index().sort_values(['total_sales','customer_id'],ascending=[False,True]).head(5).set_index('customer_id')
hours=pd.to_datetime(clean.sale_time,format='%H:%M:%S').dt.hour
clean['shift']=hours.map(lambda h:'Morning' if h<12 else 'Afternoon' if h<18 else 'Evening')
outputs['shift_orders']=clean.groupby('shift').size().reindex(['Morning','Afternoon','Evening']).rename('total_orders').to_frame()
assert outputs['category_sales'].total_orders.sum()==len(clean)==outputs['shift_orders'].total_orders.sum()
(ROOT/'results').mkdir(exist_ok=True)
for n,d in outputs.items(): d.to_csv(ROOT/'results'/f'{n}.csv',float_format='%.2f')
(ROOT/'results'/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
for n,d in outputs.items():print(n,'\n',d.to_string())
