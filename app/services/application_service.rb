# ApplicationService
# 所有 Service 的基礎類別
# Service Objects 用於處理複雜的業務邏輯，將 Controller 的邏輯抽離出來
# 這樣可以：
# 1. 提高程式碼可重用性
# 2. 方便測試
# 3. 避免 Controller 過於複雜
# 4. 在多租戶場景下，可以集中處理租戶隔離邏輯

class ApplicationService
  # 類別方法：可以直接呼叫 Service 的方法
  # 例如：CreateOrderService.call(params)
  def self.call(*args, **kwargs, &block)
    new(*args, **kwargs).call(&block)
  end

  # 實例方法：子類別需要實作
  def call
    raise NotImplementedError, "Subclass must implement #call"
  end

  protected

  # 成功回應的輔助方法
  def success(data = nil)
    { success: true, data: data }
  end

  # 失敗回應的輔助方法
  def failure(errors, status: :unprocessable_entity, code: nil)
    response = {
      success: false,
      errors: Array(errors),
      status: status
    }
    response[:error_code] = code if code
    response
  end
end

