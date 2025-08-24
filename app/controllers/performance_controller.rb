require 'benchmark'

class PerformanceController < ApplicationController
  def index
  end


  def benchmark
    @results = run_benchmark
  end

  def pagy_demo
    page_param = params[:page] || 1
    n = 50  # ビュー処理が重いので反復数を減らす
    
    @benchmark_results = Benchmark.bm(35) do |x|
      # データ取得のみのベンチマーク
      @pagy_standard_data_time = x.report("Pagy standard (data only)") do
        n.times do
          clear_query_cache
          pagy_obj, articles = pagy(Article.order(:id), items: 25, page: page_param)
          articles.to_a
        end
      end
      
      @pagy_countless_data_time = x.report("Pagy countless (data only)") do
        n.times do
          clear_query_cache
          pagy_obj, articles = pagy_countless(Article.order(:id), items: 25, page: page_param)
          articles.to_a
        end
      end
      
      # ビュー処理も含むベンチマーク
      @pagy_standard_view_time = x.report("Pagy standard (data + view)") do
        n.times do
          clear_query_cache
          pagy_obj, articles = pagy(Article.order(:id), items: 25, page: page_param)
          articles.to_a
          render_to_string('performance/_unified_pagy_content', locals: { pagy_obj: pagy_obj, articles: articles })
        end
      end
      
      @pagy_countless_view_time = x.report("Pagy countless (data + view)") do
        n.times do
          clear_query_cache
          pagy_obj, articles = pagy_countless(Article.order(:id), items: 25, page: page_param)
          articles.to_a
          render_to_string('performance/_unified_pagy_content', locals: { pagy_obj: pagy_obj, articles: articles })
        end
      end
    end
    
    # 表示用のデータを最後に取得（キャッシュクリア後）
    clear_query_cache
    @pagy, @articles = pagy_countless(Article.order(:id), items: 25, page: page_param)
    @duration = {
      data_only: [@pagy_standard_data_time.real, @pagy_countless_data_time.real],
      with_view: [@pagy_standard_view_time.real, @pagy_countless_view_time.real]
    }
  end

  def kaminari_demo
    page_param = params[:page] || 1
    n = 50  # ビュー処理が重いので反復数を減らす
    
    @benchmark_results = Benchmark.bm(35) do |x|
      # データ取得のみのベンチマーク
      @kaminari_standard_data_time = x.report("Kaminari standard (data only)") do
        n.times do
          clear_query_cache
          articles = Article.order(:id).page(page_param).per(25)
          articles.to_a
        end
      end
      
      @kaminari_no_count_data_time = x.report("Kaminari no_count (data only)") do
        n.times do
          clear_query_cache
          articles = Article.order(:id).page(page_param).per(25).without_count
          articles.to_a
        end
      end
      
      # ビュー処理も含むベンチマーク
      @kaminari_standard_view_time = x.report("Kaminari standard (data + view)") do
        n.times do
          clear_query_cache
          articles = Article.order(:id).page(page_param).per(25)
          articles.to_a
          render_to_string('performance/_unified_kaminari_content', locals: { articles: articles })
        end
      end
      
      @kaminari_no_count_view_time = x.report("Kaminari no_count (data + view)") do
        n.times do
          clear_query_cache
          articles = Article.order(:id).page(page_param).per(25).without_count
          articles.to_a
          render_to_string('performance/_unified_kaminari_content', locals: { articles: articles })
        end
      end
    end
    
    # 表示用のデータを最後に取得（キャッシュクリア後）
    clear_query_cache
    @articles = Article.order(:id).page(page_param).per(25).without_count
    @duration = {
      data_only: [@kaminari_standard_data_time.real, @kaminari_no_count_data_time.real],
      with_view: [@kaminari_standard_view_time.real, @kaminari_no_count_view_time.real]
    }
  end

  private
  
  def run_benchmark
    puts "Starting pagination performance benchmark..."
    
    test_pages = [1, 50, 100, 2000]
    n = 500
    
    results = {}
    
    test_pages.each do |page|
      puts "\nTesting page #{page}:"
      
      results[page] = Benchmark.bm(20) do |x|
        pagy_time = x.report("Pagy page #{page}") do
          n.times do
            clear_query_cache
            pagy_obj, articles = pagy(Article.order(:id), items: 25, page: page)
            articles.to_a
          end
        end
        
        kaminari_time = x.report("Kaminari page #{page}") do
          n.times do
            clear_query_cache
            articles = Article.order(:id).page(page).per(25)
            articles.to_a
          end
        end
        
        pagy_countless_time = x.report("Pagy countless #{page}") do
          n.times do
            clear_query_cache
            pagy_obj, articles = pagy_countless(Article.order(:id), items: 25, page: page)
            articles.to_a
          end
        end
        
        kaminari_no_count_time = x.report("Kaminari no count #{page}") do
          n.times do
            clear_query_cache
            articles = Article.order(:id).page(page).per(25).without_count
            articles.to_a
          end
        end
        
        [pagy_time, kaminari_time, pagy_countless_time, kaminari_no_count_time]
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
        total_records: Article.count
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
    
    results.each do |page, benchmark_results|
      page_times = {}
      
      benchmark_results.each_with_index do |result, idx|
        case idx
        when 0
          page_times[:pagy] = result.real
          total_times[:pagy] += result.real
        when 1
          page_times[:kaminari] = result.real
          total_times[:kaminari] += result.real
        when 2
          page_times[:pagy_countless] = result.real
          total_times[:pagy_countless] += result.real
        when 3
          page_times[:kaminari_no_count] = result.real
          total_times[:kaminari_no_count] += result.real
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
      "Pagy generally performs better due to simpler implementation",
      "Countless/no-count versions avoid expensive COUNT queries",
      "Performance difference increases with higher page numbers",
      "Database indexing significantly affects OFFSET performance"
    ]
    
    summary
  end

  def clear_query_cache
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear if Rails.cache.respond_to?(:clear)
  end
end
