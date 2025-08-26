module BenchmarkHelper
  extend ActiveSupport::Concern
  ORIGINAL_LOG_LEVEL = ActiveRecord::Base.logger.level

  private

  # 分岐の位置による影響を排除するため、各ベンチマークでそれぞれメソッドを分ける

  # Pagy標準版専用ベンチマーク
  # Article Count (10.0ms)  SELECT COUNT(*) FROM "articles"
  # Article Load (22.3ms)  SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT $1 OFFSET $2  [["LIMIT", 25], ["OFFSET", 49975]]
  def run_pagy_standard_benchmark(page_param: 1, per_page: 25, iterations: 50)
    ActiveRecord::Base.logger.level = Logger::ERROR

    data_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      
      time = Benchmark.realtime do
        pagy_obj, articles = pagy(Article.order(:id), items: per_page, page: page_param)
        articles.load
      end

      GC.enable
      data_time += time
    end

    nav_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
 
      time = Benchmark.realtime do
        pagy_obj, articles = pagy(Article.order(:id), items: per_page, page: page_param)
        articles.load
        view_context.pagy_nav(pagy_obj)
      end
      
      GC.enable
      nav_time += time
    end

    clear_query_cache
    @pagy, @articles = pagy(Article.order(:id), items: per_page, page: page_param)
    
    @duration = {
      data_only: data_time,
      with_nav: nav_time
    }

    ActiveRecord::Base.logger.level = ORIGINAL_LOG_LEVEL
  end

  # Pagy Countless版専用ベンチマーク
  # SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT $1 OFFSET $2  [["LIMIT", 26], ["OFFSET", 49975]]
  def run_pagy_countless_benchmark(page_param: 1, per_page: 25, iterations: 50)
    ActiveRecord::Base.logger.level = Logger::ERROR

    data_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      
      time = Benchmark.realtime do
        pagy_obj, articles = pagy_countless(Article.order(:id), items: per_page, page: page_param)
        # articles.load # countlessは即時実行されている
      end
      
      GC.enable
      data_time += time
    end

    nav_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      
      time = Benchmark.realtime do
        pagy_obj, articles = pagy_countless(Article.order(:id), items: per_page, page: page_param)
        # articles.load
        view_context.pagy_nav(pagy_obj)
      end
      
      GC.enable
      nav_time += time
    end

    clear_query_cache
    @pagy, @articles = pagy_countless(Article.order(:id), items: per_page, page: page_param)
    
    @duration = {
      data_only: data_time,
      with_nav: nav_time
    }

    ActiveRecord::Base.logger.level = ORIGINAL_LOG_LEVEL
  end

  # Kaminari標準版専用ベンチマーク
  # SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT $1 OFFSET $2  [["LIMIT", 25], ["OFFSET", 49975]]
  # SELECT COUNT(*) FROM (SELECT 1 AS one FROM "articles" LIMIT $1) subquery_for_count  [["LIMIT", 25000]]
  def run_kaminari_standard_benchmark(page_param: 1, per_page: 25, iterations: 50)
    ActiveRecord::Base.logger.level = Logger::ERROR
 
    data_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      
      time = Benchmark.realtime do
        articles = Article.order(:id).page(page_param).per(per_page)
        articles.load
      end
      
      GC.enable
      data_time += time
    end

    nav_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      
      time = Benchmark.realtime do
        articles = Article.order(:id).page(page_param).per(per_page)
        articles.load
        view_context.paginate(articles)
      end
      
      GC.enable
      nav_time += time
    end

    clear_query_cache
    @articles = Article.order(:id).page(page_param).per(per_page)
    
    @duration = {
      data_only: data_time,
      with_nav: nav_time
    }

    ActiveRecord::Base.logger.level = ORIGINAL_LOG_LEVEL
  end

  # Kaminari without_count版専用ベンチマーク
  #  SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT $1 OFFSET $2  [["LIMIT", 26], ["OFFSET", 49975]]
  def run_kaminari_without_count_benchmark(page_param: 1, per_page: 25, iterations: 50)
    ActiveRecord::Base.logger.level = Logger::ERROR
 
    data_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      
      time = Benchmark.realtime do
        articles = Article.order(:id).page(page_param).per(per_page).without_count
        articles.load
      end
      
      GC.enable
      data_time += time
    end

    nav_time = 0.0
    iterations.times do
      clear_query_cache
      GC.start
      GC.disable
      
      time = Benchmark.realtime do
        articles = Article.order(:id).page(page_param).per(per_page).without_count
        articles.load
        view_context.link_to_previous_page(articles, "← Previous")
        view_context.link_to_next_page(articles, "Next →")
      end
      
      GC.enable
      nav_time += time
    end

    clear_query_cache
    @articles = Article.order(:id).page(page_param).per(per_page).without_count
    
    @duration = {
      data_only: data_time,
      with_nav: nav_time
    }

    ActiveRecord::Base.logger.level = ORIGINAL_LOG_LEVEL
  end


  def clear_query_cache
    # ActiveRecord関連のキャッシュクリア
    ActiveRecord::Base.connection.clear_query_cache
    ActiveRecord::Base.connection_pool.connections.each(&:clear_query_cache)
    
    # Railsキャッシュのクリア
    Rails.cache.clear if Rails.cache.respond_to?(:clear)
    
    # ActionView関連のキャッシュクリア
    ActionView::Base.cache_template_loading = false if defined?(ActionView::Base)
    if defined?(ActionView::Base) && ActionView::Base.respond_to?(:clear_template_caches!)
      ActionView::Base.clear_template_caches!
    end
    if defined?(ActionView::PathResolver)
      ActionView::PathResolver.clear_cache if ActionView::PathResolver.respond_to?(:clear_cache)
    end
    
    # ActionView::LookupContextのキャッシュクリア
    if defined?(ActionView::LookupContext)
      ActionView::LookupContext.fallbacks.clear if ActionView::LookupContext.respond_to?(:fallbacks)
    end
    
    # Ruby内部キャッシュのクリア
    # メソッドキャッシュなどをクリアするため
    if defined?(RubyVM) && RubyVM.respond_to?(:stat)
      # RubyVM内部の統計情報をリセット（副作用でキャッシュもクリア）
      RubyVM.stat
    end
    
    # より強力なガベージコレクション
    3.times { GC.start }
    GC.compact if GC.respond_to?(:compact)
  end
end
