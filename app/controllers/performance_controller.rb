require 'benchmark'

class PerformanceController < ApplicationController
  include BenchmarkHelper
  def index
  end




  # Pagy 標準版
  def pagy_standard_demo
    page_param = params[:page] || 1
    run_pagy_standard_benchmark(page_param: page_param)
  end

  # Pagy Countless版
  def pagy_countless_demo
    page_param = params[:page] || 1
    run_pagy_countless_benchmark(page_param: page_param)
  end

  # Kaminari 標準版
  def kaminari_standard_demo
    page_param = params[:page] || 1
    run_kaminari_standard_benchmark(page_param: page_param)
  end

  # Kaminari without_count版
  def kaminari_without_count_demo
    page_param = params[:page] || 1
    run_kaminari_without_count_benchmark(page_param: page_param)
  end



end
