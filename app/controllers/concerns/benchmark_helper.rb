module BenchmarkHelper
  extend ActiveSupport::Concern

  private

  # 分岐の位置による影響を排除するため、各ベンチマークでそれぞれメソッドを分ける

  # Pagy標準版専用ベンチマーク
  # Article Count (10.0ms)  SELECT COUNT(*) FROM "articles"
  # Article Load (22.3ms)  SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT $1 OFFSET $2  [["LIMIT", 25], ["OFFSET", 49975]]
  # 実際に使用した際にクエリが実行される
  def run_pagy_standard_benchmark(page_param: 1, per_page: 25, iterations: 50)
    original_log_level = ActiveRecord::Base.logger.level
    
    data_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      ActiveRecord::Base.logger.level = Logger::ERROR
      
      time = Benchmark.realtime do
        pagy_obj, articles = pagy(Article.order(:id), items: per_page, page: page_param)
        articles.load
      end
      
      ActiveRecord::Base.logger.level = original_log_level
      GC.enable
      data_time += time
    end

    nav_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      ActiveRecord::Base.logger.level = Logger::ERROR
      
      time = Benchmark.realtime do
        pagy_obj, articles = pagy(Article.order(:id), items: per_page, page: page_param)
        articles.load
        view_context.pagy_nav(pagy_obj)
      end
      
      ActiveRecord::Base.logger.level = original_log_level
      GC.enable
      nav_time += time
    end

    clear_query_cache
    @pagy, @articles = pagy(Article.order(:id), items: per_page, page: page_param)
    
    @duration = {
      data_only: data_time,
      with_nav: nav_time
    }
  end

  # Pagy Countless版専用ベンチマーク
  # SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT $1 OFFSET $2  [["LIMIT", 26], ["OFFSET", 49975]]
  def run_pagy_countless_benchmark(page_param: 1, per_page: 25, iterations: 50)
    original_log_level = ActiveRecord::Base.logger.level
    
    data_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      ActiveRecord::Base.logger.level = Logger::ERROR
      
      time = Benchmark.realtime do
        pagy_obj, articles = pagy_countless(Article.order(:id), items: per_page, page: page_param)
        # articles.load # countlessは即時実行されている
      end
      
      ActiveRecord::Base.logger.level = original_log_level
      GC.enable
      data_time += time
    end

    nav_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      ActiveRecord::Base.logger.level = Logger::ERROR
      
      time = Benchmark.realtime do
        pagy_obj, articles = pagy_countless(Article.order(:id), items: per_page, page: page_param)
        # articles.load
        view_context.pagy_nav(pagy_obj)
      end
      
      ActiveRecord::Base.logger.level = original_log_level
      GC.enable
      nav_time += time
    end

    clear_query_cache
    @pagy, @articles = pagy_countless(Article.order(:id), items: per_page, page: page_param)
    
    @duration = {
      data_only: data_time,
      with_nav: nav_time
    }
  end

  # Kaminari標準版専用ベンチマーク
  # 実際の発行クエリ (Docker実測): 
  # 1. Article.page().per() 呼び出し時: SELECT "articles".* FROM "articles" /* loading for pp */ ORDER BY "articles"."id" ASC LIMIT 11 OFFSET 0
  # 2. articles.to_a 呼び出し時: SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT 25 OFFSET 0
  # 3. total_count 呼び出し時: SELECT COUNT(*) FROM (SELECT 1 AS one FROM "articles" LIMIT 25000) subquery_for_count
  def run_kaminari_standard_benchmark(page_param: 1, per_page: 25, iterations: 50)
    original_log_level = ActiveRecord::Base.logger.level
    
    data_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      ActiveRecord::Base.logger.level = Logger::ERROR
      
      time = Benchmark.realtime do
        articles = Article.order(:id).page(page_param).per(per_page)
        articles.load
      end
      
      ActiveRecord::Base.logger.level = original_log_level
      GC.enable
      data_time += time
    end

    nav_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      ActiveRecord::Base.logger.level = Logger::ERROR
      
      time = Benchmark.realtime do
        articles = Article.order(:id).page(page_param).per(per_page)
        articles.load
        view_context.paginate(articles)
      end
      
      ActiveRecord::Base.logger.level = original_log_level
      GC.enable
      nav_time += time
    end

    clear_query_cache
    @articles = Article.order(:id).page(page_param).per(per_page)
    
    @duration = {
      data_only: data_time,
      with_nav: nav_time
    }
  end

  # Kaminari without_count版専用ベンチマーク
  # 実際の発行クエリ (Docker実測): 
  # 1. Article.page().per().without_count 呼び出し時: SELECT "articles".* FROM "articles" /* loading for pp */ ORDER BY "articles"."id" ASC LIMIT 12 OFFSET 0
  # 2. articles.to_a 呼び出し時: SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT 26 OFFSET 0
  # (COUNTクエリなし - 高速化のポイント)
  def run_kaminari_without_count_benchmark(page_param: 1, per_page: 25, iterations: 50)
    original_log_level = ActiveRecord::Base.logger.level
    
    data_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      ActiveRecord::Base.logger.level = Logger::ERROR
      
      time = Benchmark.realtime do
        articles = Article.order(:id).page(page_param).per(per_page).without_count
        articles.load
      end
      
      ActiveRecord::Base.logger.level = original_log_level
      GC.enable
      data_time += time
    end

    nav_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      ActiveRecord::Base.logger.level = Logger::ERROR
      
      time = Benchmark.realtime do
        articles = Article.order(:id).page(page_param).per(per_page).without_count
        articles.load
        view_context.link_to_previous_page(articles, "← Previous")
        view_context.link_to_next_page(articles, "Next →")
      end
      
      ActiveRecord::Base.logger.level = original_log_level
      GC.enable
      nav_time += time
    end

    clear_query_cache
    @articles = Article.order(:id).page(page_param).per(per_page).without_count
    
    @duration = {
      data_only: data_time,
      with_nav: nav_time
    }
  end


  def clear_query_cache
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear if Rails.cache.respond_to?(:clear)
    ActionView::Base.cache_template_loading = false if defined?(ActionView::Base)
  end
end
