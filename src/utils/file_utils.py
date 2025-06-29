"""
File utility functions for ServerAssistant
"""

import os
import shutil
import json
from pathlib import Path
from typing import Dict, Any, List, Optional


class FileUtils:
    """Utility class for file operations"""
    
    @staticmethod
    def ensure_directory(path: str) -> bool:
        """Ensure a directory exists, create if it doesn't"""
        try:
            Path(path).mkdir(parents=True, exist_ok=True)
            return True
        except Exception as e:
            print(f"Error creating directory {path}: {e}")
            return False
            
    @staticmethod
    def read_json_file(file_path: str) -> Optional[Dict[str, Any]]:
        """Read and parse a JSON file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"File not found: {file_path}")
            return None
        except json.JSONDecodeError as e:
            print(f"Error parsing JSON file {file_path}: {e}")
            return None
        except Exception as e:
            print(f"Error reading file {file_path}: {e}")
            return None
            
    @staticmethod
    def write_json_file(file_path: str, data: Dict[str, Any], indent: int = 2) -> bool:
        """Write data to a JSON file"""
        try:
            # Ensure directory exists
            FileUtils.ensure_directory(os.path.dirname(file_path))
            
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=indent, ensure_ascii=False)
            return True
        except Exception as e:
            print(f"Error writing JSON file {file_path}: {e}")
            return False
            
    @staticmethod
    def read_text_file(file_path: str) -> Optional[str]:
        """Read a text file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
        except FileNotFoundError:
            print(f"File not found: {file_path}")
            return None
        except Exception as e:
            print(f"Error reading file {file_path}: {e}")
            return None
            
    @staticmethod
    def write_text_file(file_path: str, content: str) -> bool:
        """Write content to a text file"""
        try:
            # Ensure directory exists
            FileUtils.ensure_directory(os.path.dirname(file_path))
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        except Exception as e:
            print(f"Error writing file {file_path}: {e}")
            return False
            
    @staticmethod
    def copy_file(source: str, destination: str) -> bool:
        """Copy a file from source to destination"""
        try:
            # Ensure destination directory exists
            FileUtils.ensure_directory(os.path.dirname(destination))
            
            shutil.copy2(source, destination)
            return True
        except Exception as e:
            print(f"Error copying file from {source} to {destination}: {e}")
            return False
            
    @staticmethod
    def copy_directory(source: str, destination: str) -> bool:
        """Copy a directory from source to destination"""
        try:
            # Ensure destination directory exists
            FileUtils.ensure_directory(os.path.dirname(destination))
            
            shutil.copytree(source, destination, dirs_exist_ok=True)
            return True
        except Exception as e:
            print(f"Error copying directory from {source} to {destination}: {e}")
            return False
            
    @staticmethod
    def delete_file(file_path: str) -> bool:
        """Delete a file"""
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
                return True
            return False
        except Exception as e:
            print(f"Error deleting file {file_path}: {e}")
            return False
            
    @staticmethod
    def delete_directory(dir_path: str) -> bool:
        """Delete a directory and its contents"""
        try:
            if os.path.exists(dir_path):
                shutil.rmtree(dir_path)
                return True
            return False
        except Exception as e:
            print(f"Error deleting directory {dir_path}: {e}")
            return False
            
    @staticmethod
    def list_files(directory: str, pattern: str = "*") -> List[str]:
        """List files in a directory matching a pattern"""
        try:
            path = Path(directory)
            if not path.exists():
                return []
                
            files = []
            for file_path in path.glob(pattern):
                if file_path.is_file():
                    files.append(str(file_path))
                    
            return files
        except Exception as e:
            print(f"Error listing files in {directory}: {e}")
            return []
            
    @staticmethod
    def list_directories(directory: str) -> List[str]:
        """List subdirectories in a directory"""
        try:
            path = Path(directory)
            if not path.exists():
                return []
                
            dirs = []
            for item in path.iterdir():
                if item.is_dir():
                    dirs.append(str(item))
                    
            return dirs
        except Exception as e:
            print(f"Error listing directories in {directory}: {e}")
            return []
            
    @staticmethod
    def get_file_size(file_path: str) -> Optional[int]:
        """Get file size in bytes"""
        try:
            return os.path.getsize(file_path)
        except Exception as e:
            print(f"Error getting file size for {file_path}: {e}")
            return None
            
    @staticmethod
    def get_file_modified_time(file_path: str) -> Optional[float]:
        """Get file modification time"""
        try:
            return os.path.getmtime(file_path)
        except Exception as e:
            print(f"Error getting modification time for {file_path}: {e}")
            return None
            
    @staticmethod
    def file_exists(file_path: str) -> bool:
        """Check if a file exists"""
        return os.path.isfile(file_path)
        
    @staticmethod
    def directory_exists(dir_path: str) -> bool:
        """Check if a directory exists"""
        return os.path.isdir(dir_path)
        
    @staticmethod
    def create_backup(file_path: str, backup_suffix: str = ".backup") -> Optional[str]:
        """Create a backup of a file"""
        try:
            if not FileUtils.file_exists(file_path):
                return None
                
            backup_path = file_path + backup_suffix
            if FileUtils.copy_file(file_path, backup_path):
                return backup_path
            return None
        except Exception as e:
            print(f"Error creating backup of {file_path}: {e}")
            return None
            
    @staticmethod
    def restore_backup(backup_path: str, original_path: str) -> bool:
        """Restore a file from backup"""
        try:
            if not FileUtils.file_exists(backup_path):
                return False
                
            return FileUtils.copy_file(backup_path, original_path)
        except Exception as e:
            print(f"Error restoring backup {backup_path}: {e}")
            return False 