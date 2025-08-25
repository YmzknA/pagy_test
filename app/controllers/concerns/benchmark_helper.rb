module BenchmarkHelper
  extend ActiveSupport::Concern

  private

  # 分岐の位置による影響を排除するため、各ベンチマークでそれぞれメソッドを分ける

  # Pagy標準版専用ベンチマーク
  # 発行クエリ: 
  # 1. SELECT COUNT(*) FROM "articles"
  # 2. SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT $1 OFFSET $2
  def run_pagy_standard_benchmark(page_param: 1, per_page: 25, iterations: 100)
    @benchmark_results = Benchmark.bm(35) do |x|
      @data_time = x.report("Pagy standard (data only)") do
        iterations.times do
          clear_query_cache
          pagy_obj, articles = pagy(Article.order(:id), items: per_page, page: page_param)
          articles.to_a
        end
      end

      @view_time = x.report("Pagy standard (data + view)") do
        iterations.times do
          clear_query_cache
          pagy_obj, articles = pagy(Article.order(:id), items: per_page, page: page_param)
          articles.to_a
          render_to_string('performance/_unified_pagy_content', locals: { pagy_obj: pagy_obj, articles: articles })
        end
      end
    end

    clear_query_cache
    @pagy, @articles = pagy(Article.order(:id), items: per_page, page: page_param)
    
    @duration = {
      data_only: [@data_time.real],
      with_view: [@view_time.real]
    }
  end

  # Pagy Countless版専用ベンチマーク
  # 発行クエリ: 
  # 1. SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT $1 OFFSET $2
  # (COUNTクエリなし - 高速化のポイント)
  def run_pagy_countless_benchmark(page_param: 1, per_page: 25, iterations: 100)
    @benchmark_results = Benchmark.bm(35) do |x|
      @data_time = x.report("Pagy countless (data only)") do
        iterations.times do
          clear_query_cache
          pagy_obj, articles = pagy_countless(Article.order(:id), items: per_page, page: page_param)
          articles.to_a
        end
      end

      @view_time = x.report("Pagy countless (data + view)") do
        iterations.times do
          clear_query_cache
          pagy_obj, articles = pagy_countless(Article.order(:id), items: per_page, page: page_param)
          articles.to_a
          render_to_string('performance/_unified_pagy_content', locals: { pagy_obj: pagy_obj, articles: articles })
        end
      end
    end

    clear_query_cache
    @pagy, @articles = pagy_countless(Article.order(:id), items: per_page, page: page_param)
    
    @duration = {
      data_only: [@data_time.real],
      with_view: [@view_time.real]
    }
  end

  # Kaminari標準版専用ベンチマーク
  # 発行クエリ: 
  # 1. SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT $1 OFFSET $2
  # 2. SELECT COUNT(*) FROM (SELECT 1 AS one FROM "articles" LIMIT $1) subquery_for_count
  def run_kaminari_standard_benchmark(page_param: 1, per_page: 25, iterations: 100)
    @benchmark_results = Benchmark.bm(35) do |x|
      @data_time = x.report("Kaminari standard (data only)") do
        iterations.times do
          clear_query_cache
          articles = Article.order(:id).page(page_param).per(per_page)
          articles.to_a
        end
      end

      @view_time = x.report("Kaminari standard (data + view)") do
        iterations.times do
          clear_query_cache
          articles = Article.order(:id).page(page_param).per(per_page)
          articles.to_a
          render_to_string('performance/_unified_kaminari_content', locals: { articles: articles })
        end
      end
    end

    clear_query_cache
    @articles = Article.order(:id).page(page_param).per(per_page)
    
    @duration = {
      data_only: [@data_time.real],
      with_view: [@view_time.real]
    }
  end

  # Kaminari without_count版専用ベンチマーク
  # 発行クエリ: 
  # 1. SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT $1 OFFSET $2
  # (COUNTクエリなし - 高速化のポイント)
  def run_kaminari_without_count_benchmark(page_param: 1, per_page: 25, iterations: 100)
    @benchmark_results = Benchmark.bm(35) do |x|
      @data_time = x.report("Kaminari without_count (data only)") do
        iterations.times do
          clear_query_cache
          articles = Article.order(:id).page(page_param).per(per_page).without_count
          articles.to_a
        end
      end

      @view_time = x.report("Kaminari without_count (data + view)") do
        iterations.times do
          clear_query_cache
          articles = Article.order(:id).page(page_param).per(per_page).without_count
          articles.to_a
          render_to_string('performance/_unified_kaminari_content', locals: { articles: articles })
        end
      end
    end

    clear_query_cache
    @articles = Article.order(:id).page(page_param).per(per_page).without_count
    
    @duration = {
      data_only: [@data_time.real],
      with_view: [@view_time.real]
    }
  end


  def clear_query_cache
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear if Rails.cache.respond_to?(:clear)
  end


  # 4項目すべてをベンチマークする統合メソッド
  def run_comprehensive_benchmark(page_param: 1, per_page: 25, iterations: 100)
    @benchmark_results = Benchmark.bm(35) do |x|
      # 1. Pagy標準版 (COUNT + SELECT)
      @pagy_standard_time = x.report("Pagy standard") do
        iterations.times do
          clear_query_cache
          pagy_obj, articles = pagy(Article.order(:id), items: per_page, page: page_param)
          articles.to_a
        end
      end

      # 2. Pagy Countless版 (SELECT only)
      @pagy_countless_time = x.report("Pagy countless") do
        iterations.times do
          clear_query_cache
          pagy_obj, articles = pagy_countless(Article.order(:id), items: per_page, page: page_param)
          articles.to_a
        end
      end

      # 3. Kaminari標準版 (SELECT + COUNT with subquery)
      @kaminari_standard_time = x.report("Kaminari standard") do
        iterations.times do
          clear_query_cache
          articles = Article.order(:id).page(page_param).per(per_page)
          articles.to_a
        end
      end

      # 4. Kaminari without_count版 (SELECT only)
      @kaminari_without_count_time = x.report("Kaminari without_count") do
        iterations.times do
          clear_query_cache
          articles = Article.order(:id).page(page_param).per(per_page).without_count
          articles.to_a
        end
      end

    end

    # 実際の表示用データを各手法で取得
    clear_query_cache
    @pagy_standard, @pagy_standard_articles = pagy(Article.order(:id), items: per_page, page: page_param)
    
    clear_query_cache
    @pagy_countless, @pagy_countless_articles = pagy_countless(Article.order(:id), items: per_page, page: page_param)
    
    clear_query_cache
    @kaminari_standard_articles = Article.order(:id).page(page_param).per(per_page)
    
    clear_query_cache
    @kaminari_without_count_articles = Article.order(:id).page(page_param).per(per_page).without_count

    @duration = {
      pagy_standard: [@pagy_standard_time.real],
      pagy_countless: [@pagy_countless_time.real],
      kaminari_standard: [@kaminari_standard_time.real],
      kaminari_without_count: [@kaminari_without_count_time.real]
    }
  end
end
