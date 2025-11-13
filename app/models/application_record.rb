# ApplicationRecord
# 所有 Model 的基礎類別
# 提供共用的功能和方法

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end

