require 'benchmark'

class PerformanceController < ApplicationController
  include BenchmarkHelper
  def index
  end


  def benchmark
    @results = run_benchmark
  end

  # 統合ベンチマーク（4項目すべて）
  def comprehensive_benchmark
    page_param = params[:page] || 1
    run_comprehensive_benchmark(page_param: page_param)
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


  private
  
  def run_benchmark
    puts "Starting comprehensive pagination performance benchmark..."
    
    test_pages = [1, 50, 100, 2000]
    n = 500
    per_page = 25
    
    results = {}
    
    test_pages.each do |page|
      puts "\nTesting page #{page}:"
      
      results[page] = Benchmark.bm(25) do |x|
        # Pagy標準版
        pagy_time = x.report("Pagy standard #{page}") do
          n.times do
            clear_query_cache
            pagy_obj, articles = pagy(Article.order(:id), items: per_page, page: page)
            articles.to_a
          end
        end
        
        # Pagy Countless版
        pagy_countless_time = x.report("Pagy countless #{page}") do
          n.times do
            clear_query_cache
            pagy_obj, articles = pagy_countless(Article.order(:id), items: per_page, page: page)
            articles.to_a
          end
        end
        
        # Kaminari標準版
        kaminari_time = x.report("Kaminari standard #{page}") do
          n.times do
            clear_query_cache
            articles = Article.order(:id).page(page).per(per_page)
            articles.to_a
          end
        end
        
        # Kaminari without_count版
        kaminari_no_count_time = x.report("Kaminari no count #{page}") do
          n.times do
            clear_query_cache
            articles = Article.order(:id).page(page).per(per_page).without_count
            articles.to_a
          end
        end
        
        [pagy_time, pagy_countless_time, kaminari_time, kaminari_no_count_time]
      end
    end
    
    # Summary
    summary = analyze_benchmark_results(results, n)
    
    {
      detailed_results: results,
      summary: summary,
      test_info: {
        iterations: n,
        pages_tested: test_pages,
        per_page: per_page,
        total_records: Article.count,
        methods_tested: [
          'Pagy Standard (with COUNT)',
          'Pagy Countless (without COUNT)',
          'Kaminari Standard (with COUNT)', 
          'Kaminari without_count (without COUNT)'
        ]
      }
    }
  end
  
  def analyze_benchmark_results(results, iterations)
    summary = {
      fastest_overall: nil,
      page_winners: {},
      performance_notes: []
    }
    
    total_times = Hash.new(0)
    method_names = [:pagy_standard, :pagy_countless, :kaminari_standard, :kaminari_no_count]
    
    results.each do |page, benchmark_results|
      page_times = {}
      
      benchmark_results.each_with_index do |result, idx|
        method_name = method_names[idx]
        if method_name
          page_times[method_name] = result.real
          total_times[method_name] += result.real
        end
      end
      
      fastest_method = page_times.min_by { |_, time| time }[0]
      summary[:page_winners][page] = {
        winner: fastest_method,
        times: page_times
      }
    end
    
    summary[:fastest_overall] = total_times.min_by { |_, time| time }[0]
    summary[:total_times] = total_times
    
    summary[:performance_notes] = [
      "Pagy/Kaminari countless versions avoid expensive COUNT queries", 
      "Pagy generally has less overhead than Kaminari for standard pagination",
      "Performance difference increases significantly with higher page numbers",
      "Database indexing on ordering columns is critical for all methods"
    ]
    
    summary
  end

end
