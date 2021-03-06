require 'test_helper'

def create_test_points_odd_nodes
  a = CacheableKdtree::LatitudeLongitudeNode.new('A', 0, 0)
  b = CacheableKdtree::LatitudeLongitudeNode.new('B', -1, 7)
  c = CacheableKdtree::LatitudeLongitudeNode.new('C', 2, 5)
  d = CacheableKdtree::LatitudeLongitudeNode.new('D', -7, 12)
  e = CacheableKdtree::LatitudeLongitudeNode.new('E', -4, 5)
  f = CacheableKdtree::LatitudeLongitudeNode.new('F', 4, 10)
  g = CacheableKdtree::LatitudeLongitudeNode.new('G', 4, 3)
  [a, b, c, d, e, f, g].shuffle
end

def assert_odd_regions(tree)
  assert_region(tree.root.left.region, max_latitude: -1, max_longitude: 12, min_latitude: -7, min_longitude: 5)
  assert_region(tree.root.right.region, max_latitude: 4, max_longitude: 10, min_latitude: 2, min_longitude: 3)
  assert_region(tree.root.region, max_latitude: 4, max_longitude: 12, min_latitude: -7, min_longitude: 0)
end

def assert_odd_points(tree)
  root = tree.root
  assert_node(root, 'A')
  assert_node(root.left, 'B')
  assert_node(root.left.left, 'E')
  assert_node(root.left.right, 'D')
  assert_node(root.right, 'C')
  assert_node(root.right.left, 'G')
  assert_node(root.right.right, 'F')
end

def create_test_points_even_nodes
  a = CacheableKdtree::LatitudeLongitudeNode.new('A', 7, 2)
  b = CacheableKdtree::LatitudeLongitudeNode.new('B', 5, 4)
  c = CacheableKdtree::LatitudeLongitudeNode.new('C', 2, 3)
  d = CacheableKdtree::LatitudeLongitudeNode.new('D', 4, 7)
  e = CacheableKdtree::LatitudeLongitudeNode.new('E', 9, 6)
  f = CacheableKdtree::LatitudeLongitudeNode.new('F', 8, 1)
  [a, b, c, d, e, f].shuffle
end

def assert_even_regions(tree)
  assert_region(tree.root.left.region, max_latitude: 5, max_longitude: 7, min_latitude: 2, min_longitude: 3)
  assert_region(tree.root.right.region, max_latitude: 9, max_longitude: 6, min_latitude: 8, min_longitude: 1)
  assert_region(tree.root.region, max_latitude: 9, max_longitude: 7, min_latitude: 2, min_longitude: 1)
end

def assert_even_points(tree)
  root = tree.root
  assert_node(root, 'A')
  assert_node(root.left, 'B')
  assert_node(root.left.left, 'C')
  assert_node(root.left.right, 'D')
  assert_node(root.right, 'E')
  assert_node(root.right.left, 'F')
end

def assert_region(region, hash)
  hash.keys.each do |key|
    assert_equal hash[key], region.send(key)
  end
end

def assert_node(node, data)
  assert_equal data, node.data
end

class CacheableKdtree::LatitudeLongitudeTreeTest < Minitest::Test
  describe 'initialize' do
    it 'should create the tree properly with even number of nodes' do
      class_under_test = CacheableKdtree::LatitudeLongitudeTree.new(create_test_points_even_nodes)

      assert_even_points(class_under_test)
      assert_even_regions(class_under_test)
    end

    it 'should create the tree properly with an odd number of nodes' do
      class_under_test = CacheableKdtree::LatitudeLongitudeTree.new(create_test_points_odd_nodes)

      assert_odd_points(class_under_test)
      assert_odd_regions(class_under_test)
    end
  end

  describe 'closest' do
    it 'should raise an exception if not called with a numeric for latitude' do
      class_under_test = CacheableKdtree::LatitudeLongitudeTree.new(create_test_points_even_nodes)

      begin
        class_under_test.closest('bleh', 2.0, 3.0)
        fail 'I should not be called.'
      rescue StandardError => ex
        assert_equal ex.message, 'Input must be numeric.'
      end
    end

    it 'should raise an exception if not called with a numeric for longitude' do
      class_under_test = CacheableKdtree::LatitudeLongitudeTree.new(create_test_points_even_nodes)

      begin
        class_under_test.closest(1.0, 'bleh', 3.0)
        fail 'I should not be called.'
      rescue StandardError => ex
        assert_equal ex.message, 'Input must be numeric.'
      end
    end

    it 'should raise an exception if not called with a numeric for distances' do
      class_under_test = CacheableKdtree::LatitudeLongitudeTree.new(create_test_points_even_nodes)

      begin
        class_under_test.closest(1.0, 2.0, 'bleh')
        fail 'I should not be called.'
      rescue StandardError => ex
        assert_equal ex.message, 'Input must be numeric.'
      end
    end

    it 'should raise an exception if not called with kilometers or miles' do
      class_under_test = CacheableKdtree::LatitudeLongitudeTree.new(create_test_points_even_nodes)

      begin
        class_under_test.closest(1, 2, 3, :incorrect)
        fail 'I should not be called.'
      rescue StandardError => ex
        assert_equal ex.message, 'Units must be either :kilometers or :miles.'
      end
    end

    it 'should find the nodes within the bounding box' do
      region = CacheableKdtree::LatitudeLongitudeRegion.new(0, 0, 5, 5)
      CacheableKdtree::Util.expects(:bounding_box_miles).with(3.14, 42, 5).returns region
      class_under_test = CacheableKdtree::LatitudeLongitudeTree.new(create_test_points_odd_nodes)

      result = class_under_test.closest(3.14, 42, 5)

      assert result.any? { |node| node.data == 'A' }
      assert result.any? { |node| node.data == 'C' }
      assert result.any? { |node| node.data == 'G' }
    end

    it 'should find the nodes within the bounding box using kilometers' do
      region = CacheableKdtree::LatitudeLongitudeRegion.new(4, 8, 9, 6)
      CacheableKdtree::Util.expects(:bounding_box_kilometers).with(3.14, 42, 5).returns region
      class_under_test = CacheableKdtree::LatitudeLongitudeTree.new(create_test_points_even_nodes)

      result = class_under_test.closest(3.14, 42, 5, :kilometers)

      assert result.any? { |node| node.data == 'D' }
      assert result.any? { |node| node.data == 'E' }
    end

    it 'should find no nodes if the bounding box is outside the available nodes' do
      region = CacheableKdtree::LatitudeLongitudeRegion.new(-1, -1, -5, -5)
      CacheableKdtree::Util.expects(:bounding_box_miles).with(3.14, 42, 5).returns region
      class_under_test = CacheableKdtree::LatitudeLongitudeTree.new(create_test_points_odd_nodes)

      result = class_under_test.closest(3.14, 42, 5)

      assert_equal 0, result.length
    end
  end
end
