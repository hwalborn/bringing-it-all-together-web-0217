class Dog
  attr_accessor :name, :breed
  attr_reader :id
  def initialize(id: nil, name:, breed:)
    @id = id
    @name = name
    @breed = breed
  end

  def save
    sql = <<-SQL
      INSERT INTO dogs(name, breed)
      VALUES (?, ?)
    SQL

    DB[:conn].execute(sql, self.name, self.breed)

    @id = DB[:conn].execute("SELECT last_insert_rowid()
    FROM dogs")[0][0]
    self
  end

  def update
    sql = <<-SQL
      UPDATE dogs
      SET name = ?, breed = ?
      WHERE id = ?
    SQL
    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end

  def self.create_table
    sql = <<-SQL
    CREATE TABLE IF NOT EXISTS dogs (
      id INTEGER PRIMARY KEY,
      name TEXT,
      breed TEXT
    )
    SQL

    DB[:conn].execute(sql)
  end

  def self.create(name_hash)
    new_dog = Dog.new(name_hash)
    new_dog.save
    new_dog
  end

  def self.find_by_id(id)
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE id = ?
    SQL

    DB[:conn].execute(sql, id).map {|dog|
      Dog.new(id: dog[0], name: dog[1], breed: dog[2])
    }.first
  end

  def self.find_or_create_by(name:, breed:)
    new_dog = DB[:conn].execute("SELECT *
    FROM dogs
    WHERE name = ? AND breed = ?", name, breed)
    if !(new_dog.empty?)
      dog_arr = new_dog[0]
      dog = Dog.new(id: dog_arr[0], name: dog_arr[1], breed: dog_arr[2])
    else
      dog = self.create(name: name, breed: breed)
    end
    dog
  end

  def self.new_from_db(row)
    self.new(id: row[0], name: row[1], breed: row[2])
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE name = ?
    SQL

    DB[:conn].execute(sql, name).map {|row|
      self.new(id: row[0], name: row[1], breed: row[2])
    }.first
  end

  def self.drop_table
    DB[:conn].execute("DROP TABLE dogs")
  end
end
