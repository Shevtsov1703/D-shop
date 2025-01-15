-- Создание функции для триггера
create or replace function update_client_total_purchases()
returns trigger as $$
begin
	-- Обновить сумму выкупа по клиенту
	update Client
	set total_purchases = total_purchases + new.order_amount
	where id = new.client_id;
return new;
end
$$ language plpgsql;

-- Создание триггера, который будет вызывать функцию после вставки новой записи

create trigger after_order_insert
after insert on Orders
for each row
execute function update_client_total_purchases();

insert into Orders (client_id, order_amount)
values ('1', '133.00');

insert into Orders (client_id, order_amount)
values ('3', '189.13');

select name, total_purchases 
from Client
where id = 3;
