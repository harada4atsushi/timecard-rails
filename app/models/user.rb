class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:github, :ruffnote]

  has_many :authentications, dependent: :destroy
  has_many :members, dependent: :destroy
  has_many :issues, class_name: "Issue", foreign_key: "assignee_id"
  has_many :comments
  has_many :workloads

  validates :name, presence: true
  validates :name, uniqueness: true

  def apply_omniauth_with_github(omniauth)
    apply_omniauth(omniauth)
  end

  def github_username
    github.username
  end

  def github
    authentications.where(provider: "github").first
  end

  def apply_omniauth_with_ruffnote(omniauth)
    apply_omniauth(omniauth)
  end

  def apply_omniauth(omniauth)
    self.email = omniauth.info.email if self.email.blank?
    self.password = Devise.friendly_token[0,20] if self.encrypted_password.blank?
    name = omniauth.info.nickname
    if self.name.blank? && !User.find_by(name: name).nil?
      i = 1 
      while !User.find_by(name: "#{name}#{i}").nil?
        i += 1 
      end
      name = "#{name}#{i}"
    end
    self.name = name
    authentications.build(
      provider: omniauth.provider,
      uid: omniauth.uid,
      username: omniauth.info.nickname,
      oauth_token: omniauth.credentials.token
    )
  end

  def ruffnote_username
    ruffnote.username
  end

  def ruffnote
    authentications.where(provider: "ruffnote").first
  end

  def connected?(provider)
    authentications.where(provider: provider).exists?
  end

  def work_in_progress?(issue)
    working_issue == issue
  end

  def working_issue
    if workloads.running?
      workloads.find_by("start_at IS NOT NULL AND end_at IS NULL").issue
    else
      nil
    end
  end

  def running_workload
    workloads.find_by("start_at IS NOT NULL AND end_at IS NULL")
  end
  def selectable_providers
    Authentication.selectable_providers(self)
  end
end
