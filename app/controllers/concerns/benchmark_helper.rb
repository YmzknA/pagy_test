module BenchmarkHelper
  extend ActiveSupport::Concern

  private

  # 分岐の位置による影響を排除するため、各ベンチマークでそれぞれメソッドを分ける

  # Pagy標準版専用ベンチマーク
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

  def run_keyset_pagination_benchmark(cursor: nil, direction: 'next', per_page: 25, iterations: 100)
    @benchmark_results = Benchmark.bm(35) do |x|
      # データ取得のみのベンチマーク
      @keyset_data_time = x.report("Keyset pagination (data only)") do
        iterations.times do
          clear_query_cache
          test_cursor = cursor.present? ? cursor.to_i : nil
          if test_cursor && direction == 'prev'
            articles = Article.where('id < ?', test_cursor).order(id: :desc).limit(per_page)
          elsif test_cursor
            articles = Article.where('id > ?', test_cursor).order(:id).limit(per_page)
          else
            articles = Article.order(:id).limit(per_page)
          end
          articles.to_a
        end
      end

      # ビュー処理も含むベンチマーク
      @keyset_view_time = x.report("Keyset pagination (data + view)") do
        iterations.times do
          clear_query_cache
          test_cursor = cursor.present? ? cursor.to_i : nil
          if test_cursor && direction == 'prev'
            articles = Article.where('id < ?', test_cursor).order(id: :desc).limit(per_page)
          elsif test_cursor
            articles = Article.where('id > ?', test_cursor).order(:id).limit(per_page)
          else
            articles = Article.order(:id).limit(per_page)
          end
          articles = articles.to_a
          render_to_string('performance/_keyset_content', locals: { articles: articles })
        end
      end
    end

    # 実際の表示データを取得
    clear_query_cache
    if cursor.present? && direction == 'prev'
      @articles = Article.where('id < ?', cursor.to_i).order(id: :desc).limit(per_page).to_a.reverse
      @current_cursor = @articles.first&.id
      @prev_cursor = Article.where('id < ?', @articles.first&.id || cursor.to_i).order(id: :desc).limit(1).first&.id if @articles.any?
      @next_cursor = @articles.last&.id
    elsif cursor.present?
      @articles = Article.where('id > ?', cursor.to_i).order(:id).limit(per_page).to_a
      @current_cursor = @articles.first&.id
      @prev_cursor = cursor.to_i
      @next_cursor = @articles.last&.id
    else
      @articles = Article.order(:id).limit(per_page).to_a
      @current_cursor = @articles.first&.id
      @prev_cursor = nil
      @next_cursor = @articles.last&.id
    end

    @duration = {
      data_only: [@keyset_data_time.real],
      with_view: [@keyset_view_time.real]
    }
  end

  def clear_query_cache
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear if Rails.cache.respond_to?(:clear)
  end


  # 5項目すべてをベンチマークする統合メソッド
  def run_comprehensive_benchmark(page_param: 1, per_page: 25, iterations: 100)
    @benchmark_results = Benchmark.bm(35) do |x|
      # 1. Pagy標準版
      @pagy_standard_time = x.report("Pagy standard") do
        iterations.times do
          clear_query_cache
          pagy_obj, articles = pagy(Article.order(:id), items: per_page, page: page_param)
          articles.to_a
        end
      end

      # 2. Pagy Countless版
      @pagy_countless_time = x.report("Pagy countless") do
        iterations.times do
          clear_query_cache
          pagy_obj, articles = pagy_countless(Article.order(:id), items: per_page, page: page_param)
          articles.to_a
        end
      end

      # 3. Kaminari標準版
      @kaminari_standard_time = x.report("Kaminari standard") do
        iterations.times do
          clear_query_cache
          articles = Article.order(:id).page(page_param).per(per_page)
          articles.to_a
        end
      end

      # 4. Kaminari without_count版
      @kaminari_without_count_time = x.report("Kaminari without_count") do
        iterations.times do
          clear_query_cache
          articles = Article.order(:id).page(page_param).per(per_page).without_count
          articles.to_a
        end
      end

      # 5. Keyset Pagination
      @keyset_time = x.report("Keyset pagination") do
        cursor = page_param > 1 ? ((page_param - 1) * per_page) : nil
        iterations.times do
          clear_query_cache
          if cursor
            articles = Article.where('id > ?', cursor).order(:id).limit(per_page)
          else
            articles = Article.order(:id).limit(per_page)
          end
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
    
    # Keyset Pagination用のデータ
    clear_query_cache
    cursor = page_param > 1 ? ((page_param - 1) * per_page) : nil
    if cursor
      @keyset_articles = Article.where('id > ?', cursor).order(:id).limit(per_page).to_a
      @keyset_prev_cursor = cursor
      @keyset_next_cursor = @keyset_articles.last&.id
    else
      @keyset_articles = Article.order(:id).limit(per_page).to_a
      @keyset_prev_cursor = nil
      @keyset_next_cursor = @keyset_articles.last&.id
    end

    @duration = {
      pagy_standard: [@pagy_standard_time.real],
      pagy_countless: [@pagy_countless_time.real],
      kaminari_standard: [@kaminari_standard_time.real],
      kaminari_without_count: [@kaminari_without_count_time.real],
      keyset_pagination: [@keyset_time.real]
    }
  end
end
