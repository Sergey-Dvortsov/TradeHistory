helper = {}
colorizer = {}
fifo = {}

Recalc = class(function(acc)
end)

function Recalc:Init()
  helper=Helper()
  helper:Init()
  colorizer=Colorizer()
  colorizer:Init()
  fifo=FIFO()
  fifo:Init()
  
end

--������������� �������
function Recalc:recalcPosition(t, row, isClosed)

  local priceOpen = 	helper:getPriceOpen(t, row)
  local priceClose = 	helper:getPriceClose(t, row)
  
  local qtyClose = 		helper:getQtyClose(t, row)
  
  local sec_code =  t:GetValue(row,'secCode').image
  local class_code =  t:GetValue(row,'classCode').image

	--message(sec_code)
	--message(class_code)

  local PnL = 0
  
  local operation = tostring(t:GetValue(row, 'operation').image) --string: buy/sell
  
  if operation == 'buy' then
    PnL = priceClose - priceOpen
	
  else
    PnL = priceOpen - priceClose
	
  end
  
  local Total_PnL = PnL * qtyClose
  
  --���������� �� 4-� ������ ����� �������
  Total_PnL = math.ceil(Total_PnL * 10000)/10000 --� �������
  
  
	local mult = fifo:get_mult(sec_code, class_code)
	
	Total_PnL = Total_PnL * mult
  
    t:SetValue(row, 'profitpt', tostring(Total_PnL))
  
--����� �������� �������� ���������� ��������� ����������� �����������
  --������� �������� ���� �� 1 ���, ����� ��������� �� 10 ���, ������ ���
  --������� ceil ��������� �� ������ � ���� �� ��������� � ����, �������� 0.05 �� ������� ����!
  
  local PnL_percent = math.ceil ((PnL*10000)/priceOpen)/100   --������ ����� �� ������
  
  t:SetValue(row, 'profit %', tostring(PnL_percent)..'%')

  --���������� ������� � ������
  Recalc:rub_pnl(t, row, Total_PnL, class_code, sec_code, isClosed, mult)
  
  --��������� ���� ������ � ����������� �� ������� ��� ������
  colorizer:colorize_row(t, row, PnL)  
  
end





--this function evaluates PnL in RUB
--Parameters:
--  t           - in - table   - ID of main table
--  row         - in - numeric - number of row in table
--  Total_PnL   - in - numeric - PnL in points or currency
--  class_code  - in - string  - security class code
--  sec_code    - in - string  - security code
--  isClosed    - in - book    - position type: open/closed
--  mult        - in - numeric - multiplier for security
function Recalc:rub_pnl(t, row, Total_PnL, class_code, sec_code, isClosed, mult)

  --���������� ������� � ������
  local PnLrub = 0
  if (class_code == 'SPBFUT' or class_code=='SPBOPT' ) then
  
    local priceStep         = 0
    local stepPrice_amount  = 0
	
    if isClosed then 
      --��� ���� � ��� ��������� ����� �� ����
      priceStep         = t:GetValue(row,'close_price_step').image -- 0.1  or 0.01 or 1 or smth else
      stepPrice_amount  = t:GetValue(row,'close_price_step_price').image --6.44
	 else
      --��� ���� � ��� ��������� ����� �������, �� ��� �����������
      priceStep         = getParamEx (class_code, sec_code, 'SEC_PRICE_STEP').param_value 
      stepPrice_amount  = getParamEx (class_code, sec_code, 'STEPPRICET').param_value
    end
	
    --push price of StepPrice to main table for information
    t:SetValue(row, 'priceOfStep', tostring(stepPrice_amount))

    --������ � ������. ��� ���� � ����������� ����� �������� �� ��������������, ����� ��������� �����, �.�. � ���������� ��������� Total_PnL - ��� ��� ���������� �� �����
    PnLrub = (Total_PnL / (priceStep*mult)) * stepPrice_amount

  else
    --spot
    PnLrub = Total_PnL
  end

  --round to 2 digits after dot  
  PnLrub = math.ceil(PnLrub*100)/100
  
  --push rub PnL to main table
  t:SetValue(row, 'profit', tostring(PnLrub))
  
end

